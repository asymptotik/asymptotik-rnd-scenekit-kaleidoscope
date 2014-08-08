
attribute vec4 position;
attribute vec2 textureCoordinate;
uniform mat4 modelViewProjection;
varying vec2 texCoordVarying;

void main()
{
    gl_Position = modelViewProjection * position;
    //gl_Position = position;
    texCoordVarying = textureCoordinate;
}
