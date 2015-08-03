//
//  quadVertexBuffer.swift
//  Atk_Rnd_VisualToys
//
//  Created by Rick Boykin on 9/30/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation
import OpenGLES

class ScreenTextureQuad {
    
    var vertexBufferObject:GLuint = 0
    var normalBufferObject:GLuint = 0
    var indexBufferObject:GLuint = 0
    
    var positionIndex:GLuint = 0
    var textureCoordinateIndex:GLuint = 0
    var textureUniformIndex:GLuint = 0
    
    var glProgram:GLProgram? = nil;
    
    init() {
        
    }
    
    var min:GLfloat = -1.0
    var max:GLfloat = 1.0
    
    func initialize() {
        
        let verts:[GLfloat] = [
            min, max, 0, // vert
            0, 0, 1,      // norm
            0, 1,         // tex
            
            min, min, 0,
            0, 0, 1,
            0, 0,
            
            max, max, 0,
            0, 0, 1,
            1, 1,
            
            max, min, 0,
            0, 0, 1,
            1, 0
        ]
        
        let indices:[GLushort] = [
            0, 1, 2, 2, 1, 3
        ]
        
        let ptr = UnsafePointer<GLfloat>(bitPattern: 0)
        
        self.glProgram = GLProgram(vertexShaderFilename: "PassthroughShader", fragmentShaderFilename: "PassthroughShader")

        self.glProgram!.addAttribute("position")
        self.positionIndex = self.glProgram!.attributeIndex("position")
        self.glProgram!.addAttribute("textureCoordinate")
        self.textureCoordinateIndex = self.glProgram!.attributeIndex("textureCoordinate")
        self.glProgram!.link()
        
        self.textureUniformIndex = self.glProgram!.uniformIndex("textureUnit")
        
        // Create the buffer objects
        glGenBuffers(1, &vertexBufferObject)
        glGenBuffers(1, &indexBufferObject)
        
        // Copy data to video memory
        // Vertex data
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBufferObject)
        glBufferData(GLenum(GL_ARRAY_BUFFER), sizeof(GLfloat)*verts.count, verts, GLenum(GL_STATIC_DRAW))
        
        glEnableVertexAttribArray(self.positionIndex)
        glVertexAttribPointer(self.positionIndex, GLint(3), GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(sizeof(GLfloat) * 8), ptr)
        glEnableVertexAttribArray(self.textureCoordinateIndex)
        glVertexAttribPointer(self.textureCoordinateIndex, 2,  GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(sizeof(GLfloat) * 8), ptr.advancedBy(6))
        
        // Indexes
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexBufferObject)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), sizeof(GLushort) * indices.count, indices, GLenum(GL_STATIC_DRAW))
    }
    
    func draw(target:GLenum, name:GLuint) {
        
        glActiveTexture(GLenum(GL_TEXTURE0))
        glEnable(target)
        glBindTexture(target, name)
        
        glUniform1i(GLint(self.textureUniformIndex), 0)
        
        self.glProgram!.use()
        
        // bind VBOs for vertex array and index array
        // for vertex coordinates

        let ptr = UnsafePointer<GLfloat>(bitPattern: 0)
        
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), self.vertexBufferObject)
        
        glEnableVertexAttribArray(self.positionIndex)
        glVertexAttribPointer(self.positionIndex, GLint(3), GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(sizeof(GLfloat) * 8), ptr)
        glEnableVertexAttribArray(self.textureCoordinateIndex)
        glVertexAttribPointer(self.textureCoordinateIndex, GLint(2),  GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(sizeof(GLfloat) * 8), ptr.advancedBy(6))
        
        // Indices
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), self.indexBufferObject) // for indices
        
        // draw 2 triangle (6 indices) using offset of index array
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(6), GLenum(GL_UNSIGNED_SHORT), ptr)
        
        // bind with 0, so, switch back to normal pointer operation
        glDisableVertexAttribArray(self.positionIndex)
        glDisableVertexAttribArray(self.textureCoordinateIndex)
        
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), 0)
    }
}