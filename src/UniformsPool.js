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
  projectionMatrixInverse: (camera, shadowCamera, state, simulation) => {
    return camera.projectionMatrixInverse;
  },
  viewMatrixInverse: (camera, shadowCamera, state, simulation) => {
    return camera.matrixWorld;
  },
  viewMatrix: (camera, shadowCamera, state, simulation) => {
    return camera.matrixWorldInverse;
  },
  //SSAO
  cameraNear: (camera, shadowCamera, state, simulation) => {
    return camera.near;
  },
  cameraFar: (camera, shadowCamera, state, simulation) => {
    return camera.far;
  },
  resolution: (camera, shadowCamera, state, simulation) => {
    return new Vector2(window.innerWidth, window.innerHeight);
  },
  cameraProjectionMatrix: (camera, shadowCamera, state, simulation) => {
    return camera.projectionMatrix;
  },
  cameraInverseProjectionMatrix: (camera, shadowCamera, state, simulation) => {
    return camera.projectionMatrixInverse;
  },
  kernelRadius: (camera, shadowCamera, state, simulation) => {
    return 100.0;//8;
  },
  minDistance: (camera, shadowCamera, state, simulation) => {
    return 0.005;
  },
  maxDistance: (camera, shadowCamera, state, simulation) => {
    return 0.5;//0.05;
  },

  //GBuffer

  previousViewMatrix: (camera, shadowCamera, state, simulation) => {
    return state.previousViewMatrix;
  },

  effectColor: (camera, shadowCamera, state, simulation) => {
    return new Color(state.effectColor);
  },
  baseColor: (camera, shadowCamera, state, simulation) => {
    return new Color(state.baseColor);
  },
  baseColor2: (camera, shadowCamera, state, simulation) => {
    return new Color(state.baseColor2);
  },
  baseColor3: (camera, shadowCamera, state, simulation) => {
    return new Color(state.baseColor3);
  },
  baseColor4: (camera, shadowCamera, state, simulation) => {
    return new Color(state.baseColor4);
  },
  baseHue: (camera, shadowCamera, state, simulation) => {
    return state.baseHue;
  },
  baseSaturation: (camera, shadowCamera, state, simulation) => {
    return state.baseSaturation;
  },
  baseValue: (camera, shadowCamera, state, simulation) => {
    return state.baseValue;
  },
  baseHue2: (camera, shadowCamera, state, simulation) => {
    return state.baseHue2;
  },
  baseSaturation2: (camera, shadowCamera, state, simulation) => {
    return state.baseSaturation2;
  },
  baseValue2: (camera, shadowCamera, state, simulation) => {
    return state.baseValue2;
  },
  baseHue3: (camera, shadowCamera, state, simulation) => {
    return state.baseHue3;
  },
  baseSaturation3: (camera, shadowCamera, state, simulation) => {
    return state.baseSaturation3;
  },
  baseValue3: (camera, shadowCamera, state, simulation) => {
    return state.baseValue3;
  },
  baseHue4: (camera, shadowCamera, state, simulation) => {
    return state.baseHue4;
  },
  baseSaturation4: (camera, shadowCamera, state, simulation) => {
    return state.baseSaturation4;
  },
  baseValue4: (camera, shadowCamera, state, simulation) => {
    return state.baseValue4;
  },

  effectHue: (camera, shadowCamera, state, simulation) => {
    return state.effectHue;
  },
  effectSaturation: (camera, shadowCamera, state, simulation) => {
    return state.effectSaturation;
  },
  effectValue: (camera, shadowCamera, state, simulation) => {
    return state.effectValue;
  },

  currentPositions: (camera, shadowCamera, state, simulation) => {
    return simulation.frontForces.texture;
  },
  previousPositions: (camera, shadowCamera, state, simulation) => {
    return simulation.backForces.texture;
  },
  previousPreviousPositions: (camera, shadowCamera, state, simulation) => {
    return simulation.backBackForces.texture;
  },
  noForcesPositions: (camera, shadowCamera, state, simulation) => {
    return simulation.front.texture;
  },

  scale: (camera, shadowCamera, state, simulation) => {
    return new Vector3(state.scaleX, state.scaleY, state.scaleZ).multiplyScalar(state.scale);
  },
  squashiness: (camera, shadowCamera, state, simulation) => {
    return state.squashiness;
  },
  globalScale: (camera, shadowCamera, state, simulation) => {
    return state.globalScale;
  },
  globalRotation: (camera, shadowCamera, state, simulation) => {
    return mat3FromQuat(state.globalObjectRotation);
  },
  center: (camera, shadowCamera, state, simulation) => {
    let f = state.f;
    return new Vector3(
      state.startPosX * f + (1 - f) * state.endPosX,
      state.startPosY * f + (1 - f) * state.endPosY,
      state.startPosZ * f + (1 - f) * state.endPosZ
    );
  },

  //DepthMaterial
  shadowViewMatrix: (camera, shadowCamera, state, simulation) => {
    return shadowCamera.matrixWorldInverse;
  },
  shadowProjectionMatrix: (camera, shadowCamera, state, simulation) => {
    return shadowCamera.projectionMatrix;
  },

  //DeferedLight
  environmentMap: (camera, shadowCamera, state, simulation, map) => {
    return state.environmentOn ? map : null;
  },

  positionCamera: (camera, shadowCamera, state, simulation) => {
    return camera.position;
  },
  lightPosition: (camera, shadowCamera, state, simulation) => {
    return shadowCamera.position;
  },

  lightIntensity: (camera, shadowCamera, state, simulation) => {
    return state.lightIntensity;
  },
  lightRadius: (camera, shadowCamera, state, simulation) => {
    return state.lightRadius;
  },
  attenuationRadius: (camera, shadowCamera, state, simulation) => {
    return state.attenuationRadius;
  },

  roughness: (camera, shadowCamera, state, simulation) => {
    return state.roughness;
  },
  metallic: (camera, shadowCamera, state, simulation) => {
    return state.metallic;
  },
  u_spec: (camera, shadowCamera, state, simulation) => {
    return state.specularStrength;
  },
  ambientColor: (camera, shadowCamera, state, simulation) => {
    return new Color(state.ambientColor);
  },
  ambientIntensity: (camera, shadowCamera, state, simulation) => {
    return state.ambientIntensity;
  },
  envMapIntensity: (camera, shadowCamera, state, simulation) => {
    return state.environmentOn ? state.environmentIntensity : 0;;
  },
  toneMappingExposure: (camera, shadowCamera, state, simulation) => {
    return state.exposure;
  },
  shadowDarkness: (camera, shadowCamera, state, simulation) => {
    return state.shadowDarkness;
  },

  shadowProjectionMatrixInverse: (camera, shadowCamera, state, simulation) => {
    return shadowCamera.projectionMatrixInverse;
  },
  shadowViewMatrixInverse: (camera, shadowCamera, state, simulation) => {
    return shadowCamera.matrixWorld;
  },

  shadowRadius: (camera, shadowCamera, state, simulation) => {
    return state.shadowRadius;
  },
  shadowBias: (camera, shadowCamera, state, simulation) => {
    return state.shadowBias;
  },
  numOfPoissonDisks: (camera, shadowCamera, state, simulation) => {
    return state.useSoftShadows ? state.numOfPoissonDisks : 0;
  },
  useShadows: (camera, shadowCamera, state, simulation) => {
    return state.renderShadows ? 1.0 : 0.0;
  },
  
  // MotionBlur

  exposureTime: (camera, shadowCamera, state, simulation) => {
    return 0.75;
  },
  readScaleBias: (camera, shadowCamera, state, simulation) => {
    return new Vector2(1.0, 0.0);//new Vector2(2.0, -1.0);//new Vector2(1.0, 0.0);
  },
  
  //TileMax NeighbourMax
  writeScaleBias: (camera, shadowCamera, state, simulation) => {
    return new Vector2(1.0, 0.0);//new Vector2(0.5, 0.5);//Vector2(1.0, 0.0);
  },
  
  //Bloom

  bloomStrength: (camera, shadowCamera, state, simulation) => {
    return 0.008;//new Vector2(0.5, 0.5);//Vector2(1.0, 0.0);
  },
  filterRadius: (camera, shadowCamera, state, simulation) => {
    return 0.005;//new Vector2(0.5, 0.5);//Vector2(1.0, 0.0);
  }

};

export default UniformsPool;
