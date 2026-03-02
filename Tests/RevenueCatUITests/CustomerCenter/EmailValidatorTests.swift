//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EmailValidatorTests.swift
//
//  Created by Rosie Watson on 11/18/2025

import Nimble
@testable import RevenueCatUI
import XCTest

final class EmailValidatorTests: TestCase {

    func testValidEmail() {
        expect(EmailValidator.isValid("test@example.com")) == true
        expect(EmailValidator.isValid("user.name@example.com")) == true
        expect(EmailValidator.isValid("user+tag@example.co.uk")) == true
        expect(EmailValidator.isValid("user_name@example-domain.com")) == true
        expect(EmailValidator.isValid("123@example.com")) == true
        expect(EmailValidator.isValid("user%test@example.com")) == true
    }

    func testInvalidEmail() {
        expect(EmailValidator.isValid("")) == false
        expect(EmailValidator.isValid("notanemail")) == false
        expect(EmailValidator.isValid("@example.com")) == false
        expect(EmailValidator.isValid("user@")) == false
        expect(EmailValidator.isValid("user@.com")) == false
        expect(EmailValidator.isValid("user @example.com")) == false
        expect(EmailValidator.isValid("user@example")) == false
        expect(EmailValidator.isValid("user@example.c")) == false
        expect(EmailValidator.isValid("user@@example.com")) == false
        expect(EmailValidator.isValid("user..name@example.com")) == false
    }

    func testEmailWithSpecialCharacters() {
        expect(EmailValidator.isValid("user+filter@example.com")) == true
        expect(EmailValidator.isValid("user.name+tag@example.com")) == true
        expect(EmailValidator.isValid("user_name@example.com")) == true
        expect(EmailValidator.isValid("user-name@example.com")) == true
    }

    func testEmailWithDifferentDomains() {
        expect(EmailValidator.isValid("user@example.co")) == true
        expect(EmailValidator.isValid("user@example.co.uk")) == true
        expect(EmailValidator.isValid("user@subdomain.example.com")) == true
        expect(EmailValidator.isValid("user@example.museum")) == true
    }

}
