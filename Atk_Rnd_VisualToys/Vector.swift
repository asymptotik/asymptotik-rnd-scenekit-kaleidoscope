//
//  Vector.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 8/5/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation

struct Vector2 {
    var x: Float
    var y: Float
    
    /**
    * Negates the vector described by Vector2 and returns
    * the result as a new Vector2.
    */
    func negate() -> Vector2 {
        return self * -1
    }
    
    /**
    * Negates the vector described by Vector2
    */
    mutating func negated() -> Vector2 {
        self = negate()
        return self
    }
    
    /**
    * Returns the length (magnitude) of the vector described by the Vector2
    */
    func length() -> Float {
        return sqrtf(x*x + y*y)
    }
    
    /**
    * Normalizes the vector described by the Vector2 to length 1.0 and returns
    * the result as a new Vector2.
    */
    func normalized() -> Vector2 {
        return self / length()
    }
    
    /**
    * Normalizes the vector described by the Vector2 to length 1.0.
    */
    mutating func normalize() -> Vector2 {
        self = normalized()
        return self
    }
    
    /**
    * Calculates the distance between two Vector2. Pythagoras!
    */
    func distance(vector: Vector2) -> Float {
        return (self - vector).length()
    }
    
    /**
    * Calculates the dot product between two Vector2.
    */
    func dot(vector: Vector2) -> Float {
        return x * vector.x + y * vector.y
    }
    
    /**
    * Calculates the cross product between two Vector2.
    */
    func cross(vector: Vector2) -> Float {
        return x * vector.y - y * vector.x
    }
}

/**
 * created a new Vector2
 */
func Vector2Make(x: Float, y: Float) -> Vector2 {
    return Vector2(x: x, y: y)
}

/**
* Adds two Vector2 vectors and returns the result as a new Vector2.
*/
func + (left: Vector2, right: Vector2) -> Vector2 {
    return Vector2Make(left.x + right.x, left.y + right.y)
}

/**
* Increments a Vector2 with the value of another.
*/
func += (inout left: Vector2, right: Vector2) {
    left = left + right
}

/**
* Subtracts two Vector2 vectors and returns the result as a new Vector2.
*/
func - (left: Vector2, right: Vector2) -> Vector2 {
    return Vector2Make(left.x - right.x, left.y - right.y)
}

/**
* Decrements a Vector2 with the value of another.
*/
func -= (inout left: Vector2, right: Vector2) {
    left = left - right
}

/**
* Multiplies two Vector2 vectors and returns the result as a new Vector2.
*/
func * (left: Vector2, right: Vector2) -> Vector2 {
    return Vector2Make(left.x * right.x, left.y * right.y)
}

/**
* Multiplies a Vector2 with another.
*/
func *= (inout left: Vector2, right: Vector2) {
    left = left * right
}

/**
* Multiplies the x, y and z fields of a Vector2 with the same scalar value and
* returns the result as a new Vector2.
*/
func * (vector: Vector2, scalar: Float) -> Vector2 {
    return Vector2Make(vector.x * scalar, vector.y * scalar)
}

/**
* Multiplies the x and y fields of a Vector2 with the same scalar value.
*/
func *= (inout vector: Vector2, scalar: Float) {
    vector = vector * scalar
}

/**
* Divides two Vector2 vectors abd returns the result as a new Vector2
*/
func / (left: Vector2, right: Vector2) -> Vector2 {
    return Vector2Make(left.x / right.x, left.y / right.y)
}

/**
* Divides a Vector2 by another.
*/
func /= (inout left: Vector2, right: Vector2) {
    left = left / right
}

/**
* Divides the x, y and z fields of a Vector2 by the same scalar value and
* returns the result as a new Vector2.
*/
func / (vector: Vector2, scalar: Float) -> Vector2 {
    return Vector2Make(vector.x / scalar, vector.y / scalar)
}

/**
* Divides the x, y and z of a Vector2 by the same scalar value.
*/
func /= (inout vector: Vector2, scalar: Float) {
    vector = vector / scalar
}

/**
* Negate a vector
*/
func Vector2Negate(vector: Vector2) -> Vector2 {
    return vector * -1
}

/**
* Returns the length (magnitude) of the vector described by the Vector2
*/
func Vector2Length(vector: Vector2) -> Float
{
    return sqrtf(vector.x*vector.x + vector.y*vector.y)
}

/**
* Returns the distance between two Vector2 vectors
*/
func Vector2Distance(vectorStart: Vector2, vectorEnd: Vector2) -> Float {
    return Vector2Length(vectorEnd - vectorStart)
}

/**
* Returns the distance between two Vector2 vectors
*/
func Vector2Normalize(vector: Vector2) -> Vector2 {
    return vector / Vector2Length(vector)
}

/**
* Calculates the dot product between two Vector2 vectors
*/
func Vector2DotProduct(left: Vector2, right: Vector2) -> Float {
    return left.x * right.x + left.y * right.y
}

/**
* Calculates the cross product between two Vector2 vectors
*/
func Vector2CrossProduct(left: Vector2, right: Vector2) -> Float {
    return left.x * right.y - left.y * right.x;
}

/**
* Calculates the SCNVector from lerping between two Vector2 vectors
*/
func Vector2Lerp(vectorStart: Vector2, vectorEnd: Vector2, t: Float) -> Vector2 {
    return Vector2Make(vectorStart.x + ((vectorEnd.x - vectorStart.x) * t), vectorStart.y + ((vectorEnd.y - vectorStart.y) * t))
}

/**
* Project the vector, vectorToProject, onto the vector, projectionVector.
*/
func Vector2Project(vectorToProject: Vector2, projectionVector: Vector2) -> Vector2 {
    let scale: Float = Vector2DotProduct(projectionVector, vectorToProject) / Vector2DotProduct(projectionVector, projectionVector)
    let v: Vector2 = projectionVector * scale
    return v
}

