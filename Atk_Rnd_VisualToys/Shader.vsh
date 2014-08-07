attribute vec4 position;
attribute vec2 textureCoordinate;

varying vec2 texCoordVarying;

void main()
{
    gl_Position = position;
    texCoordVarying = textureCoordinate;
}
