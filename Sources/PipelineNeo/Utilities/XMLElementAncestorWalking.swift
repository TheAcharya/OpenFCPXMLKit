//
//  XMLElementAncestorWalking.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License


//
//	PNXMLElement extension for walking ancestor elements.
//

import Foundation

// MARK: - Walk Result Types

enum WalkAncestorsIntermediateResult<T> {
    case `continue`
    case `return`(withValue: T)
    case failure
}

enum WalkAncestorsResult<T> {
    case exhaustedAncestors
    case value(_ value: T)
    case failure
}

// MARK: - Walk Helper (free function)

private func _walkAncestorElements<T>(
    startingWith element: (any PNXMLElement)?,
    returning: T.Type,
    block: (_ element: any PNXMLElement) -> WalkAncestorsIntermediateResult<T>
) -> WalkAncestorsResult<T> {
    guard let element = element else { return .exhaustedAncestors }
    let blockResult = block(element)
    switch blockResult {
    case .continue:
        guard let parent = element.parentElement else { return .exhaustedAncestors }
        return _walkAncestorElements(startingWith: parent, returning: returning, block: block)
    case .return(let value):
        return .value(value)
    case .failure:
        return .failure
    }
}

// MARK: - PNXMLElement Ancestor Walking

extension PNXMLElement {
    /// Walk ancestors of the element.
    func walkAncestorElements(
        includingSelf: Bool,
        _ block: (_ element: any PNXMLElement) -> Bool
    ) {
        let blockWithResult: (_ element: any PNXMLElement) -> WalkAncestorsIntermediateResult<Void> = { element in
            if block(element) {
                return .continue
            } else {
                return .return(withValue: ())
            }
        }
        _ = _walkAncestorElements(
            startingWith: includingSelf ? self : parentElement,
            returning: Void.self,
            block: blockWithResult
        )
    }

    /// Walk ancestors of the element, returning a value from the block.
    func walkAncestorElements<T>(
        includingSelf: Bool,
        returning: T.Type,
        _ block: (_ element: any PNXMLElement) -> WalkAncestorsIntermediateResult<T>
    ) -> WalkAncestorsResult<T> {
        _walkAncestorElements(
            startingWith: includingSelf ? self : parentElement,
            returning: returning,
            block: block
        )
    }
}

// MARK: - Ancestor Override

extension PNXMLElement {
    /// Returns ancestor elements; if `replacement` is non-nil, uses it instead of actual ancestors.
    func ancestorElements<S: Sequence<any PNXMLElement>>(
        overrideWith replacement: S?,
        includingSelf: Bool
    ) -> AnySequence<any PNXMLElement> {
        if let replacement = replacement {
            if includingSelf {
                return ([self] + Array(replacement)).asAnySequence
            } else {
                return AnySequence(replacement)
            }
        } else {
            return ancestorElements(includingSelf: includingSelf).asAnySequence
        }
    }
}
