import vertex from "./Ortho.glslv";
import fragment from "./BloomDownsample.glslf";
import { Vector2 } from "three";

let BloomDownsample = (sizes) => {
  return {
    vertexShader: vertex,
    fragmentShader: fragment,
    uniforms: {
      u_previous: { type: "t", value: null },
      srcResolution: { type: "v2", value: new Vector2(2 * sizes.width, 2 * sizes.height) },
    },
  };
};

export default BloomDownsample;
