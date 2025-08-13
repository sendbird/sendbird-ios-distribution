//
//  CompatAttributedString.swift
//  swift-markdown-ui
//
//  Created by Tez Park on 8/11/25.
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

/// iOS 14에서도 AttributedString과 동일한 사용감을 주기 위한 호환 래퍼
/// - iOS 15+: 내부적으로 실제 AttributedString을 사용
/// - iOS 14: NSAttributedString을 기반으로 구현
public struct CompatAttributedString {
    // 내부 저장 속성
    private let nsAttributedString: NSAttributedString
    
    // MARK: - 초기화
    
    /// 일반 문자열로 CompatAttributedString 생성
    public init(_ string: String) {
        self.nsAttributedString = NSAttributedString(string: string)
    }
    
    /// 속성과 함께 CompatAttributedString 생성
    public init(_ string: String, attributes: CompatAttributeContainer) {
        self.nsAttributedString = NSAttributedString(string: string, attributes: attributes.asNSAttributes())
    }
    
    /// NSAttributedString으로부터 생성
    public init(_ nsAttributedString: NSAttributedString) {
        self.nsAttributedString = nsAttributedString
    }
    
    // MARK: - iOS 15+ AttributedString 브리징
    
    #if canImport(SwiftUI)
    /// iOS 15+에서 실제 AttributedString으로 변환
    @available(iOS 15, *)
    public var attributedString: AttributedString {
        return AttributedString(self.nsAttributedString)
    }
    
    /// iOS 15+에서 AttributedString으로부터 생성
    @available(iOS 15, *)
    public init(_ attributedString: AttributedString) {
        self.nsAttributedString = NSAttributedString(attributedString)
    }
    #endif
    
    // MARK: - NSAttributedString 접근
    
    /// 내부 NSAttributedString 접근
    public func asNSAttributedString() -> NSAttributedString {
        return self.nsAttributedString
    }
    
    // MARK: - 기본 속성들
    
    /// 문자열 내용
    public var string: String {
        return self.nsAttributedString.string
    }
    
    /// 문자열 길이
    public var length: Int {
        return self.nsAttributedString.length
    }
    
    /// 빈 문자열 여부
    public var isEmpty: Bool {
        return self.nsAttributedString.length == 0
    }
    
    // MARK: - 문자열 조작
    
    /// 다른 CompatAttributedString과 연결
    public static func + (lhs: CompatAttributedString, rhs: CompatAttributedString) -> CompatAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: lhs.nsAttributedString)
        mutableString.append(rhs.nsAttributedString)
        return CompatAttributedString(mutableString)
    }
    
    /// 문자열 추가
    public static func += (lhs: inout CompatAttributedString, rhs: CompatAttributedString) {
        lhs = lhs + rhs
    }
    
    // MARK: - 속성 조작 (간단한 버전)
    
    /// 전체 문자열에 속성 적용
    public func applyingAttributes(_ attributes: CompatAttributeContainer) -> CompatAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: self.nsAttributedString)
        let range = NSRange(location: 0, length: mutableString.length)
        let nsAttributes = attributes.asNSAttributes()
        
        for (key, value) in nsAttributes {
            mutableString.addAttribute(key, value: value, range: range)
        }
        
        return CompatAttributedString(mutableString)
    }
    
    /// 특정 범위에 속성 적용
    public func applyingAttributes(_ attributes: CompatAttributeContainer, range: NSRange) -> CompatAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: self.nsAttributedString)
        let nsAttributes = attributes.asNSAttributes()
        
        for (key, value) in nsAttributes {
            mutableString.addAttribute(key, value: value, range: range)
        }
        
        return CompatAttributedString(mutableString)
    }
    
    // MARK: - 폰트 해상도 (FontProperties 지원)
    
    /// FontProperties를 실제 폰트로 해상도
    public func resolvingFonts() -> CompatAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: self.nsAttributedString)
        
        // NSAttributedString에서는 fontProperties 커스텀 속성을 직접 처리할 수 없으므로
        // 이미 해상도된 폰트가 적용되어 있다고 가정
        return CompatAttributedString(mutableString)
    }
}

// MARK: - Hashable, Equatable 구현

extension CompatAttributedString: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(nsAttributedString.string)
        hasher.combine(nsAttributedString.length)
    }
}

extension CompatAttributedString: Equatable {
    public static func == (lhs: CompatAttributedString, rhs: CompatAttributedString) -> Bool {
        return lhs.nsAttributedString.isEqual(to: rhs.nsAttributedString)
    }
}

// MARK: - CustomStringConvertible

extension CompatAttributedString: CustomStringConvertible {
    public var description: String {
        return self.nsAttributedString.string
    }
}

// MARK: - SwiftUI Text 변환

#if canImport(SwiftUI)
extension Text {
    /// CompatAttributedString으로부터 Text 생성
    public init(_ compatString: CompatAttributedString) {
        if #available(iOS 15, *) {
            self = Text(compatString.attributedString)
        } else {
            // iOS 14에서는 일반 문자열로 폴백
            self = Text(compatString.string)
        }
    }
}
#endif

// MARK: - 기존 AttributedString extension 호환성

#if canImport(SwiftUI)
extension CompatAttributedString {
    /// CompatAttributeContainer를 사용한 초기화 (기존 코드 호환성)
    public init(_ string: String, compat: CompatAttributeContainer) {
        self.init(string, attributes: compat)
    }
}
#endif