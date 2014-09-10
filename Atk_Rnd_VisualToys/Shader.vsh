
attribute vec4 position;
attribute vec2 textureCoordinate;
uniform mat4 modelViewProjection;
varying vec2 texCoordVarying;
uniform float TexRotation;

void main()
{
    gl_Position = modelViewProjection * position;

    mat2 RotationMatrix = mat2( cos( TexRotation ), -sin( TexRotation ),
                               sin( TexRotation ),  cos( TexRotation ));
    vec2 offset = vec2(0.5, 0.5);
    
    texCoordVarying = ((textureCoordinate - offset) * RotationMatrix) + offset;
}
