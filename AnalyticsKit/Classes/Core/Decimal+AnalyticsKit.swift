//
//  Decimal+AnalyticsKit.swift
//  AnalyticsKit
//
//  Те же два хелпера, что в CoreKit. Намеренно internal: пакет не тянет
//  CoreKit ради четырёх строк, а internal не конфликтует с публичной версией
//  в приложении.
//

import Foundation

extension Decimal {

    var nsDecimalNumber: NSDecimalNumber { NSDecimalNumber(decimal: self) }

    var double: Double { nsDecimalNumber.doubleValue }
}
