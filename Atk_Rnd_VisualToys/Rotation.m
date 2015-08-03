//
//  Rotation.m
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 10/11/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

#import "Rotation.h"


@implementation Rotation

+(CGPoint)rotateCamera:(SCNNode *)cameraNode velocity:(CGPoint)slideVelocity {
    
    //spin the camera according the the user's swipes
    SCNQuaternion oldRot = cameraNode.rotation;  //get the current rotation of the camera as a quaternion
    GLKQuaternion rot = GLKQuaternionMakeWithAngleAndAxis(oldRot.w, oldRot.x, oldRot.y, oldRot.z);  //make a GLKQuaternion from the SCNQuaternion
    
    CGFloat viewSlideDivisor = 0.01745329252 * 0.1;
    
    //The next function calls take these parameters: rotationAngle, xVector, yVector, zVector
    //The angle is the size of the rotation (radians) and the vectors define the axis of rotation
    GLKQuaternion rotX = GLKQuaternionMakeWithAngleAndAxis(-slideVelocity.x * viewSlideDivisor, 0, 1, 0); //For rotation when swiping with X we want to rotate *around* y axis, so if our vector is 0,1,0 that will be the y axis
    GLKQuaternion rotY = GLKQuaternionMakeWithAngleAndAxis(-slideVelocity.y * viewSlideDivisor, 1, 0, 0); //For rotation by swiping with Y we want to rotate *around* the x axis.  By the same logic, we use 1,0,0
    GLKQuaternion netRot = GLKQuaternionMultiply(rotX, rotY); //To combine rotations, you multiply the quaternions.  Here we are combining the x and y rotations
    rot = GLKQuaternionMultiply(rot, netRot); //finally, we take the current rotation of the camera and rotate it by the new modified rotation.
    
    //Then we have to separate the GLKQuaternion into components we can feed back into SceneKit
    GLKVector3 axis = GLKQuaternionAxis(rot);
    float angle = GLKQuaternionAngle(rot);
    
    //finally we replace the current rotation of the camera with the updated rotation
    cameraNode.rotation = SCNVector4Make(axis.x, axis.y, axis.z, angle);
    
    //This specific implementation uses velocity.  If you don't want that, use the rotation method above just replace slideVelocity.
    //decrease the slider velocity
    if (slideVelocity.x > -1 && slideVelocity.x < 1) {
        slideVelocity.x = 0;
    }
    else {
        slideVelocity.x *= 0.5;
    }
    
    if (slideVelocity.y > -1 && slideVelocity.y < 1) {
        slideVelocity.y = 0;
    }
    else {
        slideVelocity.y *= 0.5;
    }
    
    NSLog(@"velocity: %f %f", slideVelocity.x, slideVelocity.y);
    
    return slideVelocity;
}

@end
