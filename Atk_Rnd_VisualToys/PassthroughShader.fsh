varying highp vec2 texCoordVarying;
uniform sampler2D textureUnit;

void main()
{
    mediump vec4 rgb = texture2D(textureUnit, texCoordVarying);
    gl_FragColor = rgb; //vec4(1,0,0,1); //
}