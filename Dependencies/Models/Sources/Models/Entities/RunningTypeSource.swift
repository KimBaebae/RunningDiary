//
//  RunningTypeSource.swift
//  Models
//
//  Created by 김혜지 on 9/8/26.
//

/// `runningType` 판별에 사용된 근거. 서버와 값 이름을 합의했으므로 임의로 바꾸지 않는다.
public enum RunningTypeSource: String, Sendable, Equatable {
    case healthKit
    case distanceInference
}
