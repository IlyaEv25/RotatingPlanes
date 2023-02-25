import vertex from "./Ortho.glslv";
import fragment from "./MotionBlur.glslf";
import { DataTexture, RedFormat, FloatType, RepeatWrapping } from "three";
import { SimplexNoise } from "three/examples/jsm/math/SimplexNoise"

let randomBuffer;

function makeRandomBuffer() {
    let simplex = new SimplexNoise();
    let N = 32;
    let size = N * N;
    let data = new Float32Array( size );
    
    for ( let i = 0; i < size; i ++ ) {

        const x = ( Math.random() * 2 ) - 1;
        const y = ( Math.random() * 2 ) - 1;
        const z = 0;

        data[ i ] = simplex.noise3d( x, y, z )
    }

    randomBuffer = new DataTexture( data, N, N, RedFormat, FloatType );
    randomBuffer.wrapS = RepeatWrapping;
    randomBuffer.wrapT = RepeatWrapping;
    randomBuffer.needsUpdate = true;
}

makeRandomBuffer();

let MotionBlur = {
  defines: {},

  uniforms: {
    u_velocity: { type: "t", value: null },
    u_color: { type: "t", value: null },
    u_neighbour: { type: "t", value: null },
    u_depth: { type: "t", value: null },
    randomBuffer: { type: "t", value: randomBuffer },
    exposureTime: { type: "f", value: null },
    readScaleBias: { type: "v2", value: null }
  },
  fragmentShader: fragment,
  vertexShader: vertex,
};

export default MotionBlur;
