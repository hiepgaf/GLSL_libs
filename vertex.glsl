varying vec4 coord;

void main() {
  coord = gl_TexCoord;
  gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
}