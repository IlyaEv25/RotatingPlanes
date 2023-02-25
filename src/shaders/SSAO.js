import { SimplexNoise } from "three/examples/jsm/math/SimplexNoise"
import { Vector2, Vector3, Matrix4, MathUtils, DataTexture, RepeatWrapping, RedFormat, FloatType } from "three"
import fragment from "./SSAO.glslf";
import vertex from "./Ortho.glslv";

let kernelSize = 32;
let kernel = [];
let noiseTexture;

function generateSampleKernel() {

    for ( let i = 0; i < kernelSize; i ++ ) {

        const sample = new Vector3();
        sample.x = ( Math.random() * 2 ) - 1;
        sample.y = ( Math.random() * 2 ) - 1;
        sample.z = Math.random();

        sample.normalize();

        let scale = i / kernelSize;
        scale = MathUtils.lerp( 0.1, 1, scale * scale );
        sample.multiplyScalar( scale );

        kernel.push( sample );

    }

}

function generateRandomKernelRotations() {

    const width = 4, height = 4;

    if ( SimplexNoise === undefined ) {

        console.error( 'THREE.SSAOPass: The pass relies on SimplexNoise.' );

    }

    const simplex = new SimplexNoise();

    const size = width * height;
    const data = new Float32Array( size );

    for ( let i = 0; i < size; i ++ ) {

        const x = ( Math.random() * 2 ) - 1;
        const y = ( Math.random() * 2 ) - 1;
        const z = 0;

        data[ i ] = simplex.noise3d( x, y, z );

    }

    noiseTexture = new DataTexture( data, width, height, RedFormat, FloatType );
    noiseTexture.wrapS = RepeatWrapping;
    noiseTexture.wrapT = RepeatWrapping;
    noiseTexture.needsUpdate = true;

}

generateRandomKernelRotations();
generateSampleKernel();

let SSAO = {
    defines: {
		'PERSPECTIVE_CAMERA': 1,
		'KERNEL_SIZE': 32
	},

	uniforms: {

		'u_normal': { value: null },
		'u_depth': { value: null },
		'u_noise': { value: noiseTexture },
		'kernel': { value: kernel },
		'cameraNear': { value: null },
		'cameraFar': { value: null },
		'resolution': { value: new Vector2() },
        'viewMatrix': { value: new Matrix4() },
		'cameraProjectionMatrix': { value: new Matrix4() },
		'cameraInverseProjectionMatrix': { value: new Matrix4() },
		'kernelRadius': { value: 100 }, //8
		'minDistance': { value: 0.005 },
		'maxDistance': { value: 1.0 }//{ value: 0.05 },

	},
    fragmentShader: fragment,
    vertexShader: vertex 
}

export default SSAO;