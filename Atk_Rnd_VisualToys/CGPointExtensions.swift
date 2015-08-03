//
//  CGPointExtensions.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 10/11/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation
import UIKit

/**
* Adds two CGPoint vectors and returns the result as a new CGPoint.
*/
func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPointMake(left.x + right.x, left.y + right.y)
}

/**
* Increments a CGPoint with the value of another.
*/
func += (inout left: CGPoint, right: CGPoint) {
    left = left + right
}

/**
* Subtracts two CGPoint vectors and returns the result as a new CGPoint.
*/
func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPointMake(left.x - right.x, left.y - right.y)
}

/**
* Decrements a CGPoint with the value of another.
*/
func -= (inout left: CGPoint, right: CGPoint) {
    left = left - right
}

/**
* Multiplies two CGPoint vectors and returns the result as a new CGPoint.
*/
func * (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPointMake(left.x * right.x, left.y * right.y)
}

/**
* Multiplies a CGPoint with another.
*/
func *= (inout left: CGPoint, right: CGPoint) {
    left = left * right
}

/**
* Multiplies the x, y and z fields of a CGPoint with the same scalar value and
* returns the result as a new CGPoint.
*/
func * (vector: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPointMake(vector.x * scalar, vector.y * scalar)
}

/**
* Multiplies the x and y fields of a CGPoint with the same scalar value.
*/
func *= (inout vector: CGPoint, scalar: CGFloat) {
    vector = vector * scalar
}

/**
* Divides two CGPoint vectors abd returns the result as a new CGPoint
*/
func / (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPointMake(left.x / right.x, left.y / right.y)
}

/**
* Divides a CGPoint by another.
*/
func /= (inout left: CGPoint, right: CGPoint) {
    left = left / right
}

/**
* Divides the x, y and z fields of a CGPoint by the same scalar value and
* returns the result as a new CGPoint.
*/
func / (vector: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPointMake(vector.x / scalar, vector.y / scalar)
}

/**
* Divides the x, y and z of a CGPoint by the same scalar value.
*/
func /= (inout vector: CGPoint, scalar: CGFloat) {
    vector = vector / scalar
}
