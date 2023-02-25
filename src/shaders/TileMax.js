import vertex from "./Ortho.glslv";
import fragment from "./TileMax.glslf";

let TileMax = {
  defines: {},

  uniforms: {
    u_velocity: { type: "t", value: null },
    resolution:  { type: "v2", value: null },
    readScaleBias: { type: "v2", value: null },
    writeScaleBias: { type: "v2", value: null }
  },
  fragmentShader: fragment,
  vertexShader: vertex,
};

export default TileMax;
