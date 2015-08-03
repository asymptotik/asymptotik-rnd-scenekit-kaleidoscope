//
//  Rotation.h
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 10/11/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>
#import <GLKit/GLKit.h>

@interface Rotation : NSObject

+(CGPoint)rotateCamera:(SCNNode *)cameraNode velocity:(CGPoint)slideVelocity;

@end
