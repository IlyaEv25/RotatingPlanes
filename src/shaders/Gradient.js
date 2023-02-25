import vertex from "./Ortho.glslv"
import fragment from "./Gradient.glslf"

let Gradient = {
  uniforms: {
    colorTop: { type: "v3", value: null },
    colorBottom: { type: "v3", value: null },
  },
  vertexShader: vertex,
  fragmentShader: fragment,
};

export default Gradient;
