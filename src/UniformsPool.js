//Promote to a class?
import { Matrix3, Matrix4, Vector2, Vector3, Color } from "three";

function mat3FromQuat(quat) {
  let mat4 = new Matrix4().makeRotationFromQuaternion(quat);
  return new Matrix3().setFromMatrix4(mat4);
}

let UniformsPool = {
  //Common
  modelMatrix: null,
  modelViewMatrix: null,
  projectionMatrix: null,
  projectionMatrixInverse: (scene, state, previousUniformsObjects) => {
    return scene.camera.projectionMatrixInverse;
  },
  viewMatrixInverse: (scene, state, previousUniformsObjects) => {
    return scene.camera.matrixWorld;
  },
  viewMatrix: (scene, state, previousUniformsObjects) => {
    return scene.camera.matrixWorldInverse;
  },
  //SSAO
  cameraNear: (scene, state, previousUniformsObjects) => {
    return scene.camera.near;
  },
  cameraFar: (scene, state, previousUniformsObjects) => {
    return scene.camera.far;
  },
  resolution: (scene, state, previousUniformsObjects) => {
    return new Vector2( window.innerWidth,  window.innerHeight);
  },
  cameraProjectionMatrix: (scene, state, previousUniformsObjects) => {
    return scene.camera.projectionMatrix;
  },
  cameraInverseProjectionMatrix: (scene, state, previousUniformsObjects) => {
    return scene.camera.projectionMatrixInverse;
  },
  kernelRadius: (scene, state, previousUniformsObjects) => {
    return 100.0; //8;
  },
  minDistance: (scene, state, previousUniformsObjects) => {
    return 0.005;
  },
  maxDistance: (scene, state, previousUniformsObjects) => {
    return 0.5; //0.05;
  },

  //GBuffer

  previousViewMatrix: (scene, state, previousUniformsObjects) => {
    return previousUniformsObjects[0].viewMatrix? previousUniformsObjects[0].viewMatrix : new Matrix4();
  },

  //DepthMaterial
  shadowViewMatrix: (scene, state, previousUniformsObjects) => {
    let matrices = [];
    scene.lights.forEach((light, index) => {
      matrices.push(light.shadowCamera? light.shadowCamera.matrixWorldInverse: new Matrix4());
    });

    return matrices;
  },
  shadowProjectionMatrix: (scene, state, previousUniformsObjects) => {
    let matrices = [];
    scene.lights.forEach((light, index) => {
      matrices.push(light.shadowCamera? light.shadowCamera.projectionMatrix: new Matrix4());
    });

    return matrices;
  },

  //DeferedLight
  environmentMap: (scene, state, previousUniformsObjects, simulation, map) => {
    return state.environmentOn ? map : null;
  },

  positionCamera: (scene, state, previousUniformsObjects) => {
    return scene.camera.position;
  },

  envMapIntensity: (scene, state, previousUniformsObjects) => {
    return state.environmentOn ? state.environmentIntensity : 0;
  },
  shadowDarkness: (scene, state, previousUniformsObjects) => {
    return state.shadowDarkness;
  },

  shadowProjectionMatrixInverse: (scene, state, previousUniformsObjects) => {
    let matrices = [];
    scene.lights.forEach((light, index) => {
      matrices.push(light.shadowCamera? light.shadowCamera.projectionMatrixInverse: new Matrix4());
    });

    return matrices;
  },
  shadowViewMatrixInverse: (scene, state, previousUniformsObjects) => {
    let matrices = [];
    scene.lights.forEach((light, index) => {
      
      matrices.push(light.shadowCamera? light.shadowCamera.matrixWorld : new Matrix4());
    });

    return matrices;
  },

  shadowRadius: (scene, state, previousUniformsObjects) => {
    return state.shadowRadius;
  },
  shadowBias: (scene, state, previousUniformsObjects) => {
    return state.shadowBias;
  },
  numOfPoissonDisks: (scene, state, previousUniformsObjects) => {
    return state.useSoftShadows ? state.numOfPoissonDisks : 0;
  },


  // MotionBlur

  exposureTime: (scene, state, previousUniformsObjects) => {
    return 0.75;
  },
  readScaleBias: (scene, state, previousUniformsObjects) => {
    return new Vector2(1.0, 0.0); //new Vector2(2.0, -1.0);//new Vector2(1.0, 0.0);
  },

  //TileMax NeighbourMax
  writeScaleBias: (scene, state, previousUniformsObjects) => {
    return new Vector2(1.0, 0.0); //new Vector2(0.5, 0.5);//Vector2(1.0, 0.0);
  },

  //Bloom

  bloomStrength: (scene, state, previousUniformsObjects) => {
    return 0.015;//0.008; //new Vector2(0.5, 0.5);//Vector2(1.0, 0.0);
  },
  filterRadius: (scene, state, previousUniformsObjects) => {
    return 0.005; //0.005 //new Vector2(0.5, 0.5);//Vector2(1.0, 0.0);
  },

  //Final

  toneMappingExposure: (scene, state, previousUniformsObjects) => {
    return 1; //new Vector2(0.5, 0.5);//Vector2(1.0, 0.0);
  }
};

export default UniformsPool;
