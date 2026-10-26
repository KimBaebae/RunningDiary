//
//  CreateDiaryPayloadSizer.swift
//  Models
//
//  Created by Claude on 9/8/26.
//

import Foundation

/// `CreateDiaryRequest`를 서버 상한 이하로 맞춰 인코딩한다.
///
/// 계약 문서: `docs/api/create-diary-request.md` "body 크기 제한". 서버는 5MiB를 넘으면
/// `413`으로 거절하므로, 앱은 4.5MiB를 자체 상한으로 두고 이를 넘는 인코딩 결과는 전송 전에
/// route를 추가로 균등 축약해 재인코딩한다.
public enum CreateDiaryPayloadSizer {
    /// 서버 상한 5MiB에 대해 앱이 두는 자체 상한.
    public static let defaultLimitBytes = 4_718_592   // 4.5 MiB = 4.5 * 1024 * 1024

    public struct Output: Equatable, Sendable {
        public let request: CreateDiaryRequest
        public let data: Data
    }

    public enum SizingError: Error, Equatable {
        /// route를 더 줄일 수 없는데도 상한을 넘는다.
        case irreducible(byteCount: Int)
    }

    /// `request`를 인코딩하고, 결과가 `limit`을 넘으면 route를 이진 탐색으로 축약해 재인코딩한다.
    ///
    /// `routeOriginalPointCount`는 다운샘플 이전 원본 개수를 그대로 유지하고,
    /// 추가 축약이 일어나면 `routeSamplingMethod`는 `uniform`으로 바뀐다.
    public static func fit(
        _ request: CreateDiaryRequest,
        limit: Int = defaultLimitBytes
    ) throws -> Output {
        let data = try encode(request)

        guard data.count > limit else {
            return Output(request: request, data: data)
        }

        guard
            let route = request.workout.route,
            route.count > 1
        else {
            throw SizingError.irreducible(byteCount: data.count)
        }

        // 지점 1개로도 상한을 넘으면 이진 탐색을 돌 필요 없이 바로 실패한다.
        let smallestCandidate = try makeCandidate(from: request, route: route, maxPoints: 1)

        guard smallestCandidate.data.count <= limit else {
            throw SizingError.irreducible(byteCount: smallestCandidate.data.count)
        }

        // 상한 이하가 되는 가장 큰 지점 수를 찾는다. 지점이 많을수록 경로 해상도가 높으므로
        // "가능한 한 적게 줄인" 결과를 남긴다.
        var low = 1
        var high = route.count - 1
        var best = smallestCandidate

        while low <= high {
            let mid = low + (high - low) / 2
            let candidate = try makeCandidate(from: request, route: route, maxPoints: mid)

            if candidate.data.count <= limit {
                best = candidate
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        return best
    }

    private static func makeCandidate(
        from request: CreateDiaryRequest,
        route: [RoutePointRequest],
        maxPoints: Int
    ) throws -> Output {
        let reducedPoints = RouteDownsampler.uniformlyReduced(route, maxPoints: maxPoints)
        let reducedWorkout = request.workout.replacingRoute(
            points: reducedPoints,
            samplingMethod: SeriesSamplingMethod.uniform.rawValue
        )
        let reducedRequest = request.replacingWorkout(reducedWorkout)
        let data = try encode(reducedRequest)

        return Output(request: reducedRequest, data: data)
    }

    private static func encode(_ request: CreateDiaryRequest) throws -> Data {
        try JSONEncoder().encode(request)
    }
}
