import vertex from "./Ortho.glslv";
import fragment from "./NeighbourMax.glslf";

let NeighbourMax = {
  defines: {},

  uniforms: {
    u_tile: { type: "t", value: null },
    readScaleBias: { type: "v2", value: null },
    writeScaleBias: { type: "v2", value: null }
  },
  fragmentShader: fragment,
  vertexShader: vertex,
};

export default NeighbourMax;
