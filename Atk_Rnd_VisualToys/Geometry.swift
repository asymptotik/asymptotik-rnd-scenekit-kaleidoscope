//
//  Geometry.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 8/8/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation
import SceneKit

class Geometry {
    
    class func createKaleidoscopeMirrorWithEquilateralTriangles(view:SCNView) -> SCNGeometry {
        
        let extents = view.getExtents()
        let minEx   = extents.min
        let maxEx   = extents.max
        
        println("minEx: (\(minEx.x), \(minEx.y), \(minEx.z)) maxEx: (\(maxEx.x), \(maxEx.y), \(maxEx.z))")
        
        let r:Float = 1.0;
        let tri_scale:Float = 1.0;
        
        var co:Float = Float(cos(M_PI/3.0) * Double(r)); //0.5
        var si:Float = Float(sin(M_PI/3.0) * Double(r)); //0.86
        
        let tri_width:Float = r * tri_scale
        let tri_height:Float = si * tri_scale
        
        println("tri_width: \(tri_width) tri_height: \(tri_height)")
        
        let width:Float = maxEx.x - minEx.x
        let height:Float = maxEx.y - minEx.y
        
        println("width: \(width) height: \(height)")
        
        let triCountX:Float = ceil(width  / tri_width)
        let xOffset:Float = -(triCountX * tri_width / Float(2.0))
        
        let triCountY:Float = ceil(height  / tri_height)
        let yOffset:Float = -(triCountY * tri_height / Float(2.0))
        
        println("xOffset: \(xOffset) triCountX: \(triCountX)")
        println("yOffset: \(yOffset) triCountY: \(triCountY)")
        println("tri_width: \(tri_width) tri_height: \(tri_height)")
        
        let uva  = Vector2Make(0.0, 0.0)
        let uvb  = Vector2Make(1.0, 0.0)
        let uvc  = Vector2Make(0.5, 1.0)
        let norm = SCNVector3Make(0.0, 0.0, 1.0)
        
        var vertices:[SCNVector3] = []
        var normals:[SCNVector3] = []
        var uvs:[Vector2] = []
        var indices:[CInt] = []
        
        var numTriangles = 0
        var numPrimitives = 0
        
        var vertCountY = Int(triCountY) + 1
        first: for var j:Int = 0; j < vertCountY; j++ {
            
            var startY:Float = tri_height*Float(j)
            startY += yOffset;
            
            var ucArray = (j % 2 == 0 ? [uvb, uva, uvc] : [uva, uvc, uvb])
            var actualTriCountX = Int(triCountX) + (j % 2 == 0 ? 0 : 1)
            var vertCountX = Int(actualTriCountX) + 1
            
            for var i:Int = 0; i < vertCountX; i++ {
                
                var startX:Float =  (tri_width * Float(i)) - (j % 2 == 0 ? 0.0 : tri_width / 2.0)
                startX += xOffset
            
                vertices.append(SCNVector3( x: startX, y: startY, z: 0.0 ))
                normals.append(norm)
                uvs.append(ucArray[i % 3])
            }
            
            if j > 0 {
                
                if j % 2 == 1 {
                    var lineVert = vertices.count - vertCountX;
                    var prevLineVert = vertices.count - (vertCountX + vertCountX - 1);
                    
                    for var i:Int = 0; i < vertCountX - 2; ++i {
                        
                        indices.append(CInt(lineVert))
                        indices.append(CInt(prevLineVert))
                        indices.append(CInt(lineVert) + 1)
                        
                        indices.append(CInt(lineVert) + 1)
                        indices.append(CInt(prevLineVert))
                        indices.append(CInt(prevLineVert) + 1)
                        
                        ++prevLineVert;
                        ++lineVert;
                    }
                    
                    indices.append(CInt(lineVert))
                    indices.append(CInt(prevLineVert))
                    indices.append(CInt(lineVert) + 1)
                    
                } else {
                    
                    var lineVert = vertices.count - vertCountX;
                    var prevLineVert = vertices.count - (vertCountX + vertCountX + 1);
                    
                    for var i:Int = 0; i < vertCountX - 1; ++i {
                        
                        indices.append(CInt(prevLineVert))
                        indices.append(CInt(prevLineVert) + 1)
                        indices.append(CInt(lineVert))
                        
                        indices.append(CInt(lineVert))
                        indices.append(CInt(prevLineVert) + 1)
                        indices.append(CInt(lineVert) + 1)
                        
                        ++prevLineVert;
                        ++lineVert;
                    }
                    
                    indices.append(CInt(prevLineVert))
                    indices.append(CInt(prevLineVert) + 1)
                    indices.append(CInt(lineVert))
                }
            }
        }
        
        let primitiveCount = indices.count / 3
        
        // Vertices
        let vertexData = NSData(bytes: vertices, length: vertices.count * sizeof(SCNVector3))
        var vertexSource = SCNGeometrySource(data: vertexData,
            semantic: SCNGeometrySourceSemanticVertex,
            vectorCount: vertices.count,
            floatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(SCNVector3))
        
        // Normals
        let normalData = NSData(bytes: normals, length: normals.count * sizeof(SCNVector3))
        var normalSource = SCNGeometrySource(data: normalData,
            semantic: SCNGeometrySourceSemanticNormal,
            vectorCount: normals.count,
            floatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(SCNVector3))
        
        // Textures
        let uvData = NSData(bytes: uvs, length: uvs.count * sizeof(Vector2))
        var uvSource = SCNGeometrySource(data: uvData,
            semantic: SCNGeometrySourceSemanticTexcoord,
            vectorCount: uvs.count,
            floatComponents: true,
            componentsPerVector: 2,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(Vector2))
        
        // Indices
        var elements:[SCNGeometryElement] = []
        var indexData  = NSData(bytes: indices, length: sizeof(CInt) * indices.count)
        var indexElement = SCNGeometryElement(
            data: indexData,
            primitiveType: .Triangles,
            primitiveCount: primitiveCount,
            bytesPerIndex: sizeof(CInt)
        )
        
        elements.append(indexElement)
        
        var geo = SCNGeometry(sources: [vertexSource, normalSource, uvSource], elements: elements)
        
        return geo
    }
    
    class func createKaleidoscopeMirrorWithIsoscelesTriangles(view:SCNView) -> SCNGeometry {
        
        let extents = view.getExtents()
        let minEx   = extents.min
        let maxEx   = extents.max
        
        println("minEx: (\(minEx.x), \(minEx.y), \(minEx.z)) maxEx: (\(maxEx.x), \(maxEx.y), \(maxEx.z))")
        
        let r:Float = 1.0;
        let tri_scale:Float = 2.0; //(float)randInt(120, 400);

        let tri_width:Float = 1.0 * tri_scale
        let tri_height:Float = 1.0 * tri_scale
        
        println("tri_width: \(tri_width) tri_height: \(tri_height)")
        
        let width:Float = maxEx.x - minEx.x
        let height:Float = maxEx.y - minEx.y
        
        println("width: \(width) height: \(height)")
        
        let triCountX:Float = ceil(width  / tri_width)
        let xOffset:Float = -(triCountX * tri_width / Float(2.0))
        
        let triCountY:Float = ceil(height  / tri_height)
        let yOffset:Float = -(triCountY * tri_height / Float(2.0))
        
        println("xOffset: \(xOffset) triCountX: \(triCountX)")
        println("yOffset: \(yOffset) triCountY: \(triCountY)")
        println("tri_width: \(tri_width) tri_height: \(tri_height)")
        
        let uva  = Vector2Make(0.0, 0.0)
        let uvb  = Vector2Make(1.0, 0.0)
        let uvc  = Vector2Make(0.5, 1.0)
        let norm = SCNVector3Make(0.0, 0.0, 1.0)
        
        var vertices:[SCNVector3] = []
        var normals:[SCNVector3] = []
        var uvs:[Vector2] = []
        var indices:[CInt] = []
        
        var numTriangles = 0
        var numPrimitives = 0
        
        var vertCountY = Int(triCountY) + 1
        first: for var j:Int = 0; j < vertCountY; j++ {
            
            var startY:Float = tri_height*Float(j)
            startY += yOffset;
            
            var ucArray = (j % 2 == 0 ? [uvc, uva] : [uvb, uvc])
            var actualTriCountX = Int(triCountX)
            var vertCountX = Int(actualTriCountX) + 1
            
            for var i:Int = 0; i < vertCountX; i++ {
                
                var startX:Float =  (tri_width * Float(i))
                startX += xOffset
                
                vertices.append(SCNVector3( x: startX, y: startY, z: 0.0 ))
                normals.append(norm)
                uvs.append(ucArray[i % 2])
            }
            
            let phase = (j % 2 == 1 ? 0 : 1)
            if j > 0 {
                
                var lineVert = vertices.count - vertCountX;
                var prevLineVert = vertices.count - (vertCountX + vertCountX);
                
                for var i:Int = 0; i < vertCountX - 1; ++i {
                    
                    if i % 2 == phase {
                        indices.append(CInt(prevLineVert))
                        indices.append(CInt(prevLineVert) + 1)
                        indices.append(CInt(lineVert))
                    
                        indices.append(CInt(lineVert))
                        indices.append(CInt(prevLineVert) + 1)
                        indices.append(CInt(lineVert) + 1)
                    }
                    else {
                        indices.append(CInt(lineVert))
                        indices.append(CInt(prevLineVert))
                        indices.append(CInt(lineVert) + 1)
                        
                        indices.append(CInt(lineVert) + 1)
                        indices.append(CInt(prevLineVert))
                        indices.append(CInt(prevLineVert) + 1)
                    }
                    
                    ++prevLineVert;
                    ++lineVert;
                }
            }
        }
        
        let primitiveCount = indices.count / 3
        
        // Vertices
        let vertexData = NSData(bytes: vertices, length: vertices.count * sizeof(SCNVector3))
        var vertexSource = SCNGeometrySource(data: vertexData,
            semantic: SCNGeometrySourceSemanticVertex,
            vectorCount: vertices.count,
            floatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(SCNVector3))
        
        // Normals
        let normalData = NSData(bytes: normals, length: normals.count * sizeof(SCNVector3))
        var normalSource = SCNGeometrySource(data: normalData,
            semantic: SCNGeometrySourceSemanticNormal,
            vectorCount: normals.count,
            floatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(SCNVector3))
        
        // Textures
        let uvData = NSData(bytes: uvs, length: uvs.count * sizeof(Vector2))
        var uvSource = SCNGeometrySource(data: uvData,
            semantic: SCNGeometrySourceSemanticTexcoord,
            vectorCount: uvs.count,
            floatComponents: true,
            componentsPerVector: 2,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(Vector2))
        
        // Indices
        var elements:[SCNGeometryElement] = []
        var indexData  = NSData(bytes: indices, length: sizeof(CInt) * indices.count)
        var indexElement = SCNGeometryElement(
            data: indexData,
            primitiveType: .Triangles,
            primitiveCount: primitiveCount,
            bytesPerIndex: sizeof(CInt)
        )
        
        elements.append(indexElement)
        
        var geo = SCNGeometry(sources: [vertexSource, normalSource, uvSource], elements: elements)
        
        return geo
    }
    
    class func createKaleidoscopeMirrorWithHexagons(view:SCNView) -> SCNGeometry {
        
        let extents = view.getExtents()
        let minEx = extents.min
        let maxEx = extents.max
        
        println("minEx: (\(minEx.x), \(minEx.y), \(minEx.z)) maxEx: (\(maxEx.x), \(maxEx.y), \(maxEx.z))")
        
        let r:Float = 1.0;
        let tri_scale:Float = 2.0; //(float)randInt(120, 400);
        
        var co:Float = Float(cos(M_PI/3.0) * Double(r)); //0.5
        var si:Float = Float(sin(M_PI/3.0) * Double(r)); //0.86
        
        let tri_width:Float = r * tri_scale
        let tri_height:Float = si * tri_scale
        
        println("tri_width: \(tri_width) tri_height: \(tri_height)")
        
        let width:Float = maxEx.x - minEx.x
        let height:Float = maxEx.y - minEx.y
        
        println("width: \(width) height: \(height)")
        
        let triCountX:Float = ceil(width / tri_width / Float(1.5))
        let w:Float = ((triCountX * Float(1.5)) + Float(0.5)) * tri_width
        let xOffset:Float = -(w/Float(2.0)) + tri_width
        
        var h = height  / (tri_height * Float(2.0))
        println("h: \(h)")
        
        let triCountY:Float = ceil(height  / (tri_height * Float(2.0))) + 1
        let yOffset:Float = -(triCountY * (tri_height * Float(2.0)) - tri_height) / Float(2.0)
        
        println("xOffset: \(xOffset) triCountX: \(triCountX)")
        println("yOffset: \(yOffset) triCountY: \(triCountY)")
        println("tri_width: \(tri_width) tri_height: \(tri_height)")
        
        let uva  = Vector2Make(0.0, 0.0)
        let uvb  = Vector2Make(1.0, 0.0)
        let uvc  = Vector2Make(0.5, 1.0)
        let norm = SCNVector3Make(0.0, 0.0, 1.0)
        
        var vertices:[SCNVector3] = [];
        var normals:[SCNVector3] = [];
        var uvs:[Vector2] = [];
        
        var numTriangles = 0
        var numPrimitives = 0
        
        // creates a series of hexagons composed of 6 triangles each
        first: for( var i:Float = 0; i < triCountX; i++ ) {
            var startX:Float = ((tri_width) * 1.5 * i)
            startX += xOffset
            for( var j:Float = 0; j < triCountY; j++ ) {
                var startY:Float = (i%2==0) ? (tri_height*2*j) : tri_height*2*j + (tri_height)
                startY += yOffset;
                
                var scale = SCNVector3( x: tri_scale, y: tri_scale, z: 1.0 )
                var start = SCNVector3( x: startX, y: startY, z: 0.0 )
                //var start = SCNVector3( x: 0.0, y: 0.0, z: 0.0 )
                
                vertices.append(SCNVector3Make(0.0, 0.0, 0.0) + start)
                vertices.append(SCNVector3Make(r, 0.0, 0.0) * scale + start)
                vertices.append(SCNVector3Make(co, si, 0.0) * scale + start)
                
                normals.append(norm)
                normals.append(norm)
                normals.append(norm)
                
                uvs.append(uva)
                uvs.append(uvb)
                uvs.append(uvc)
                
                
                vertices.append(SCNVector3Make(0.0, 0.0, 0.0) + start)
                vertices.append(SCNVector3Make(co, si, 0.0) * scale + start)
                vertices.append(SCNVector3Make(-co, si, 0.0) * scale + start)
                
                normals.append(norm)
                normals.append(norm)
                normals.append(norm)
                
                uvs.append(uva)
                uvs.append(uvc)
                uvs.append(uvb)
                
                
                vertices.append(SCNVector3Make(0.0, 0.0, 0.0) + start)
                vertices.append(SCNVector3Make(-co, si, 0.0) * scale + start)
                vertices.append(SCNVector3Make(-r, 0.0, 0.0) * scale + start)
                
                normals.append(norm)
                normals.append(norm)
                normals.append(norm)
                
                uvs.append(uva)
                uvs.append(uvb)
                uvs.append(uvc)
                
                
                vertices.append(SCNVector3Make(0.0, 0.0, 0.0) + start)
                vertices.append(SCNVector3Make(-r, 0.0, 0.0) * scale + start)
                vertices.append(SCNVector3Make(-co, -si, 0.0) * scale + start)
                
                normals.append(norm)
                normals.append(norm)
                normals.append(norm)
                
                uvs.append(uva)
                uvs.append(uvc)
                uvs.append(uvb)
                
                
                vertices.append(SCNVector3Make(0.0, 0.0, 0.0) + start)
                vertices.append(SCNVector3Make(-co, -si, 0.0) * scale + start)
                vertices.append(SCNVector3Make(co, -si, 0.0) * scale + start)
                
                normals.append(norm)
                normals.append(norm)
                normals.append(norm)
                
                uvs.append(uva)
                uvs.append(uvb)
                uvs.append(uvc)
                
                
                vertices.append(SCNVector3Make(0.0, 0.0, 0.0) + start)
                vertices.append(SCNVector3Make(co, -si, 0.0) * scale + start)
                vertices.append(SCNVector3Make(r, 0.0, 0.0) * scale + start)
                
                normals.append(norm)
                normals.append(norm)
                normals.append(norm)
                
                uvs.append(uva)
                uvs.append(uvc)
                uvs.append(uvb)
                
                numTriangles += 6
            }
        }
        
        let primitiveCount = vertices.count / 3
        
        // Vertices
        let vertexData = NSData(bytes: vertices, length: vertices.count * sizeof(SCNVector3))
        var vertexSource = SCNGeometrySource(data: vertexData,
            semantic: SCNGeometrySourceSemanticVertex,
            vectorCount: vertices.count,
            floatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(SCNVector3))
        
        // Normals
        let normalData = NSData(bytes: normals, length: normals.count * sizeof(SCNVector3))
        var normalSource = SCNGeometrySource(data: normalData,
            semantic: SCNGeometrySourceSemanticNormal,
            vectorCount: normals.count,
            floatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(SCNVector3))
        
        // Textures
        let uvData = NSData(bytes: uvs, length: uvs.count * sizeof(Vector2))
        var uvSource = SCNGeometrySource(data: uvData,
            semantic: SCNGeometrySourceSemanticTexcoord,
            vectorCount: uvs.count,
            floatComponents: true,
            componentsPerVector: 2,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(Vector2))
        
        
        var elements:[SCNGeometryElement] = []
        
        // Indexes
        
        /*
        for primitive in 0..<primitiveCount {
        
        let min:CInt = CInt(primitive * 3)
        let max:CInt = CInt((primitive + 1) * 3)
        var indices:[CInt] = []
        
        for var n:CInt = min; n < max; ++n {
        indices.append(n)
        }
        
        var indexData  = NSData(bytes: indices, length: sizeof(CInt) * indices.count)
        var indexElement = SCNGeometryElement(
        data: indexData,
        primitiveType: .Triangles,
        primitiveCount: 3,
        bytesPerIndex: sizeof(CInt)
        )
        
        elements.append(indexElement)
        }
        */
        
        var indices:[CInt] = []
        
        for n in 0..<vertices.count {
            indices.append(CInt(n))
        }
        
        var indexData  = NSData(bytes: indices, length: sizeof(CInt) * indices.count)
        var indexElement = SCNGeometryElement(
            data: indexData,
            primitiveType: .Triangles,
            primitiveCount: primitiveCount,
            bytesPerIndex: sizeof(CInt)
        )
        
        elements.append(indexElement)
        
        var geo = SCNGeometry(sources: [vertexSource, normalSource, uvSource], elements: elements)
        
        return geo
    }
    
    class func createQuad(view:SCNView) -> SCNGeometry {
        
        let extents = view.getExtents()
        let minEx   = extents.min
        let maxEx   = extents.max
        
        // Vertices
        var vertices:[SCNVector3] = [
            SCNVector3Make(minEx.x, maxEx.y, 0.0),
            SCNVector3Make(minEx.x, minEx.y, 0.0),
            SCNVector3Make(maxEx.x, maxEx.y, 0.0),
            SCNVector3Make(maxEx.x, minEx.y, 0.0)
        ]
        
        let vertexData = NSData(bytes: vertices, length: vertices.count * sizeof(SCNVector3))
        var vertexSource = SCNGeometrySource(data: vertexData,
            semantic: SCNGeometrySourceSemanticVertex,
            vectorCount: vertices.count,
            floatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(SCNVector3))
        
        // Normals
        var normals:[SCNVector3] = [
            SCNVector3Make(0.0, 0.0, 1.0),
            SCNVector3Make(0.0, 0.0, 1.0),
            SCNVector3Make(0.0, 0.0, 1.0),
            SCNVector3Make(0.0, 0.0, 1.0)
        ]
        
        let normalData = NSData(bytes: normals, length: normals.count * sizeof(SCNVector3))
        var normalSource = SCNGeometrySource(data: normalData,
            semantic: SCNGeometrySourceSemanticNormal,
            vectorCount: normals.count,
            floatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(SCNVector3))
        
        // Texture
        var uvs:[Vector2] = [
            Vector2Make(0.0, 1.0),
            Vector2Make(1.0, 1.0),
            Vector2Make(0.0, 0.0),
            Vector2Make(1.0, 0.0)
        ]
        
        let uvData = NSData(bytes: uvs, length: uvs.count * sizeof(Vector2))
        var uvSource = SCNGeometrySource(data: uvData,
            semantic: SCNGeometrySourceSemanticTexcoord,
            vectorCount: uvs.count,
            floatComponents: true,
            componentsPerVector: 2,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(Vector2))
        
        // Indexes
        var indices:[CInt] = [0, 1, 2, 2, 1, 3]
        var indexData  = NSData(bytes: indices, length: sizeof(CInt) * indices.count)
        var indexElement = SCNGeometryElement(
            data: indexData,
            primitiveType: .Triangles,
            primitiveCount: 2,
            bytesPerIndex: sizeof(CInt)
        )
        
        var geo = SCNGeometry(sources: [vertexSource, normalSource, uvSource], elements: [indexElement])
        
        let me2 = UIImage(named: "me2")
        
        // material
        var material = SCNMaterial()
        material.diffuse.contents  = me2
        material.doubleSided = true
        material.shininess = 1.0;
        geo.materials = [material];
        
        return geo
    }
    
    class func createUnitQuad(view:SCNView) -> SCNGeometry {
        
        let extents = view.getExtents()
        let minEx   = extents.min
        let maxEx   = extents.max
        
        // Vertices
        var vertices:[SCNVector3] = [
            SCNVector3Make(-1, 1, 0.0),
            SCNVector3Make(-1, -1, 0.0),
            SCNVector3Make(1, 1, 0.0),
            SCNVector3Make(1, -1, 0.0)
        ]
        
        let vertexData = NSData(bytes: vertices, length: vertices.count * sizeof(SCNVector3))
        var vertexSource = SCNGeometrySource(data: vertexData,
            semantic: SCNGeometrySourceSemanticVertex,
            vectorCount: vertices.count,
            floatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(SCNVector3))
        
        // Normals
        var normals:[SCNVector3] = [
            SCNVector3Make(0.0, 0.0, 1.0),
            SCNVector3Make(0.0, 0.0, 1.0),
            SCNVector3Make(0.0, 0.0, 1.0),
            SCNVector3Make(0.0, 0.0, 1.0)
        ]
        
        let normalData = NSData(bytes: normals, length: normals.count * sizeof(SCNVector3))
        var normalSource = SCNGeometrySource(data: normalData,
            semantic: SCNGeometrySourceSemanticNormal,
            vectorCount: normals.count,
            floatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(SCNVector3))
        
        // Texture
        var uvs:[Vector2] = [
            Vector2Make(0.0, 1.0),
            Vector2Make(1.0, 1.0),
            Vector2Make(0.0, 0.0),
            Vector2Make(1.0, 0.0)
        ]
        
        let uvData = NSData(bytes: uvs, length: uvs.count * sizeof(Vector2))
        var uvSource = SCNGeometrySource(data: uvData,
            semantic: SCNGeometrySourceSemanticTexcoord,
            vectorCount: uvs.count,
            floatComponents: true,
            componentsPerVector: 2,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(Vector2))
        
        // Indexes
        var indices:[CInt] = [0, 1, 2, 2, 1, 3]
        var indexData  = NSData(bytes: indices, length: sizeof(CInt) * indices.count)
        var indexElement = SCNGeometryElement(
            data: indexData,
            primitiveType: .Triangles,
            primitiveCount: 2,
            bytesPerIndex: sizeof(CInt)
        )
        
        var geo = SCNGeometry(sources: [vertexSource, normalSource, uvSource], elements: [indexElement])
        
        return geo
    }

    
    class func createTriangle(view:SCNView) -> SCNGeometry {
        
        // Vertices
        var vertices:[SCNVector3] = [
            SCNVector3Make(-1.0, -1.0, 0.0),
            SCNVector3Make(1.0, -1.0, 0.0),
            SCNVector3Make(0.0, 1.0, 0.0)
        ]
        
        let vertexData = NSData(bytes: vertices, length: vertices.count * sizeof(SCNVector3))
        var vertexSource = SCNGeometrySource(data: vertexData,
            semantic: SCNGeometrySourceSemanticVertex,
            vectorCount: vertices.count,
            floatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(SCNVector3))
        
        // Normals
        var normals:[SCNVector3] = [
            SCNVector3Make(0.0, 0.0, 1.0),
            SCNVector3Make(0.0, 0.0, 1.0),
            SCNVector3Make(0.0, 0.0, 1.0)
        ]
        
        let normalData = NSData(bytes: normals, length: normals.count * sizeof(SCNVector3))
        var normalSource = SCNGeometrySource(data: normalData,
            semantic: SCNGeometrySourceSemanticNormal,
            vectorCount: normals.count,
            floatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(SCNVector3))
        
        // Texture
        var uvs:[Vector2] = [
            Vector2Make(0.0, 0.0),
            Vector2Make(1.0, 0.0),
            Vector2Make(0.5, 1.0)
        ]
        
        let uvData = NSData(bytes: uvs, length: uvs.count * sizeof(Vector2))
        var uvSource = SCNGeometrySource(data: uvData,
            semantic: SCNGeometrySourceSemanticTexcoord,
            vectorCount: uvs.count,
            floatComponents: true,
            componentsPerVector: 2,
            bytesPerComponent: sizeof(Float),
            dataOffset: 0,
            dataStride: sizeof(Vector2))
        
        // Indexes
        var indices:[CInt] = [0, 1, 2]
        var indexData  = NSData(bytes: indices, length: sizeof(CInt) * indices.count)
        var indexElement = SCNGeometryElement(
            data: indexData,
            primitiveType: .Triangles,
            primitiveCount: 1,
            bytesPerIndex: sizeof(CInt)
        )
        
        var geo = SCNGeometry(sources: [vertexSource, normalSource, uvSource], elements: [indexElement])
        
        let me2 = UIImage(named: "me2")
        
        // material
        var material = SCNMaterial()
        material.diffuse.contents  = me2
        material.doubleSided = true
        material.shininess = 1.0;
        geo.materials = [material];
        
        return geo
    }
    
    class func createCube(view:SCNView) -> SCNGeometry {
        var halfSide:Float = 1.0;
        
        var positions = [
            SCNVector3Make(-halfSide, -halfSide,  halfSide),
            SCNVector3Make( halfSide, -halfSide,  halfSide),
            SCNVector3Make(-halfSide, -halfSide, -halfSide),
            SCNVector3Make( halfSide, -halfSide, -halfSide),
            SCNVector3Make(-halfSide,  halfSide,  halfSide),
            SCNVector3Make( halfSide,  halfSide,  halfSide),
            SCNVector3Make(-halfSide,  halfSide, -halfSide),
            SCNVector3Make( halfSide,  halfSide, -halfSide),
            
            // repeat exactly the same
            SCNVector3Make(-halfSide, -halfSide,  halfSide),
            SCNVector3Make( halfSide, -halfSide,  halfSide),
            SCNVector3Make(-halfSide, -halfSide, -halfSide),
            SCNVector3Make( halfSide, -halfSide, -halfSide),
            SCNVector3Make(-halfSide,  halfSide,  halfSide),
            SCNVector3Make( halfSide,  halfSide,  halfSide),
            SCNVector3Make(-halfSide,  halfSide, -halfSide),
            SCNVector3Make( halfSide,  halfSide, -halfSide),
            
            // repeat exactly the same
            SCNVector3Make(-halfSide, -halfSide,  halfSide),
            SCNVector3Make( halfSide, -halfSide,  halfSide),
            SCNVector3Make(-halfSide, -halfSide, -halfSide),
            SCNVector3Make( halfSide, -halfSide, -halfSide),
            SCNVector3Make(-halfSide,  halfSide,  halfSide),
            SCNVector3Make( halfSide,  halfSide,  halfSide),
            SCNVector3Make(-halfSide,  halfSide, -halfSide),
            SCNVector3Make( halfSide,  halfSide, -halfSide)
        ]
        
        var normals = [
            SCNVector3Make( 0, -1, 0),
            SCNVector3Make( 0, -1, 0),
            SCNVector3Make( 0, -1, 0),
            SCNVector3Make( 0, -1, 0),
            
            SCNVector3Make( 0, 1, 0),
            SCNVector3Make( 0, 1, 0),
            SCNVector3Make( 0, 1, 0),
            SCNVector3Make( 0, 1, 0),
            
            
            SCNVector3Make( 0, 0,  1),
            SCNVector3Make( 0, 0,  1),
            SCNVector3Make( 0, 0, -1),
            SCNVector3Make( 0, 0, -1),
            
            SCNVector3Make( 0, 0, 1),
            SCNVector3Make( 0, 0, 1),
            SCNVector3Make( 0, 0, -1),
            SCNVector3Make( 0, 0, -1),
            
            
            SCNVector3Make(-1, 0, 0),
            SCNVector3Make( 1, 0, 0),
            SCNVector3Make(-1, 0, 0),
            SCNVector3Make( 1, 0, 0),
            
            SCNVector3Make(-1, 0, 0),
            SCNVector3Make( 1, 0, 0),
            SCNVector3Make(-1, 0, 0),
            SCNVector3Make( 1, 0, 0)
        ]
        
        var indexes:[CInt] = [
            // bottom
            0, 2, 1,
            1, 2, 3,
            // back
            10, 14, 11,  // 2, 6, 3,   + 8
            11, 14, 15,  // 3, 6, 7,   + 8
            // left
            16, 20, 18,  // 0, 4, 2,   + 16
            18, 20, 22,  // 2, 4, 6,   + 16
            // right
            17, 19, 21,  // 1, 3, 5,   + 16
            19, 23, 21,  // 3, 7, 5,   + 16
            // front
            8,  9, 12,  // 0, 1, 4,   + 8
            9, 13, 12,  // 1, 5, 4,   + 8
            // top
            4, 5, 6,
            5, 7, 6
        ]
        
        var vertexSource = SCNGeometrySource(vertices: &positions, count: 24)
        var normalSource = SCNGeometrySource(normals: &normals, count: 24)
        
        var dat  = NSData(
            bytes: indexes,
            length: sizeof(CInt) * indexes.count
        )
        
        var ele = SCNGeometryElement(
            data: dat,
            primitiveType: .Triangles,
            primitiveCount: 12,
            bytesPerIndex: sizeof(CInt)
        )
        
        var geo = SCNGeometry(sources: [vertexSource, normalSource], elements: [ele])
        
        var material = SCNMaterial()
        material.diffuse.contents  = UIColor.redColor()
        geo.materials = [material];
        
        return geo
    }
    
}