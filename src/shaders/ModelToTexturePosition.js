import vertex from "./ModelToTexturePosition.glslv"
import fragment from "./ModelToTexturePosition.glslf"

let ModelToTexturePosition = {
  uniforms: {
    
  },
  vertexShader: vertex,
  fragmentShader: fragment,
};

export default ModelToTexturePosition;