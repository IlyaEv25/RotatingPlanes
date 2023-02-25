import shaderLoad from "./shaders";
import { FloatType } from "three";
let shaders = shaderLoad();

let gBuffer = () => {
  return {
    name: "gBuffer",
    type: "GBufferPass",
    shader: shaders.GBufferParticles,
    numberOfColorAttachments: 3,
    isDepthTarget: true,
    width: (sizes) => {
      return sizes.width;
    },
    height: (sizes) => {
      return sizes.height;
    },
    clear: true,
    textureType: FloatType,
  };
};

let SSAO = () => {
  return {
    name: "SSAO",
    type: "QuadPass",
    shader: shaders.SSAO,
    numberOfColorAttachments: 1,
    isDepthTarget: false,
    width: (sizes) => {
      return sizes.width;
    },
    height: (sizes) => {
      return sizes.height;
    },
    clear: true,
    textureType: FloatType,
  };
};
let shadow = () => {
  return {
    name: "shadow",
    type: "OverrideMaterialScenePass",
    shader: shaders.DepthMaterialParticles,
    numberOfColorAttachments: 1,
    isDepthTarget: true,
    width: (sizes) => {
      return sizes.width;
    },
    height: (sizes) => {
      return sizes.height;
    },
    clear: true,
    textureType: FloatType,
  };
};
let tilemaxY = () => {
  return {
    name: "tilemaxY",
    type: "QuadPass",
    shader: shaders.TileMax,
    numberOfColorAttachments: 1,
    isDepthTarget: false,
    width: (sizes) => {
      return sizes.height;
    },
    height: (sizes) => {
      return Math.floor(sizes.width / 20);
    },
    clear: true,
    textureType: FloatType,
  };
};
let tilemaxX = () => {
  return {
    name: "tilemaxX",
    type: "QuadPass",
    shader: shaders.TileMax,
    numberOfColorAttachments: 1,
    isDepthTarget: false,
    width: (sizes) => {
      return Math.floor(sizes.width / 20);
    },
    height: (sizes) => {
      return Math.floor(sizes.height / 20);
    },
    clear: true,
    textureType: FloatType,
  };
};
let neighbourmax = () => {
  return {
    name: "neighbourmax",
    type: "QuadPass",
    shader: shaders.NeighbourMax,
    numberOfColorAttachments: 1,
    isDepthTarget: false,
    width: (sizes) => {
      return Math.floor(sizes.width / 20);
    },
    height: (sizes) => {
      return Math.floor(sizes.height / 20);
    },
    clear: true,
    textureType: FloatType,
  };
};
let motionblur = () => {
  return {
    name: "motionblur",
    type: "QuadPass",
    shader: shaders.MotionBlur,
    numberOfColorAttachments: 1,
    isDepthTarget: false,
    width: (sizes) => {
      return sizes.width;
    },
    height: (sizes) => {
      return sizes.height;
    },
    clear: true,
    textureType: FloatType,
  };
};
let taaresolve = () => {
  return {
    name: "taaresolve",
    type: "QuadPass",
    shader: shaders.TAAResolve,
    numberOfColorAttachments: 1,
    isDepthTarget: true,
    width: (sizes) => {
      return sizes.width;
    },
    height: (sizes) => {
      return sizes.height;
    },
    clear: true,
    textureType: FloatType,
  };
};
let accumulation = () => {
  return {
    name: "accumulation",
    type: "QuadPass",
    shader: shaders.Accumulate,
    numberOfColorAttachments: 1,
    isDepthTarget: true,
    width: (sizes) => {
      return sizes.width;
    },
    height: (sizes) => {
      return sizes.height;
    },
    clear: true,
    textureType: FloatType,
  };
};

let light = () => {
  return {
    name: "light",
    type: "LightPass",
    shader: shaders.DeferedLight,
    numberOfColorAttachments: 1,
    isDepthTarget: true,
    width: (sizes) => {
      return sizes.width;
    },
    height: (sizes) => {
      return sizes.height;
    },
    clear: true,
    textureType: FloatType,
  };
};

let bloomDown1 = () => {
  return {
    name: "bloomDown1",
    type: "QuadPass",
    shader: shaders.BloomDownsample,
    shaderArguments: "size",
    numberOfColorAttachments: 1,
    isDepthTarget: false,
    width: (sizes) => {
      return Math.floor(sizes.width / Math.pow(2, 1));
    },
    height: (sizes) => {
      return Math.floor(sizes.height / Math.pow(2, 1));
    },
    clear: true,
    textureType: FloatType,
  };
};

let bloomDown2 = () => {
  return {
    name: "bloomDown2",
    type: "QuadPass",
    shader: shaders.BloomDownsample,
    shaderArguments: "size",
    numberOfColorAttachments: 1,
    isDepthTarget: false,
    width: (sizes) => {
      return Math.floor(sizes.width / Math.pow(2, 2));
    },
    height: (sizes) => {
      return Math.floor(sizes.height / Math.pow(2, 2));
    },
    clear: true,
    textureType: FloatType,
  };
};

let bloomDown3 = () => {
  return {
    name: "bloomDown3",
    type: "QuadPass",
    shader: shaders.BloomDownsample,
    shaderArguments: "size",
    numberOfColorAttachments: 1,
    isDepthTarget: false,
    width: (sizes) => {
      return Math.floor(sizes.width / Math.pow(2, 3));
    },
    height: (sizes) => {
      return Math.floor(sizes.height / Math.pow(2, 3));
    },
    clear: true,
    textureType: FloatType,
  };
};

let bloomDown4 = () => {
  return {
    name: "bloomDown4",
    type: "QuadPass",
    shader: shaders.BloomDownsample,
    shaderArguments: "size",
    numberOfColorAttachments: 1,
    isDepthTarget: false,
    width: (sizes) => {
      return Math.floor(sizes.width / Math.pow(2, 4));
    },
    height: (sizes) => {
      return Math.floor(sizes.height / Math.pow(2, 4));
    },
    clear: true,
    textureType: FloatType,
  };
};

let bloomDown5 = () => {
  return {
    name: "bloomDown5",
    type: "QuadPass",
    shader: shaders.BloomDownsample,
    shaderArguments: "size",
    numberOfColorAttachments: 1,
    isDepthTarget: false,
    width: (sizes) => {
      return Math.floor(sizes.width / Math.pow(2, 5));
    },
    height: (sizes) => {
      return Math.floor(sizes.height / Math.pow(2, 5));
    },
    clear: true,
    textureType: FloatType,
  };
};

let bloomUp1 = () => {
  return {
    name: "bloomUp1",
    type: "QuadPass",
    shader: shaders.BloomUpsample(false),
    numberOfColorAttachments: 1,
    isDepthTarget: false,
    width: (sizes) => {
      return Math.floor(sizes.width / Math.pow(2, 4));
    },
    height: (sizes) => {
      return Math.floor(sizes.height / Math.pow(2, 4));
    },
    clear: true,
    textureType: FloatType,
  };
};

let bloomUp2 = () => {
  return {
    name: "bloomUp2",
    type: "QuadPass",
    shader: shaders.BloomUpsample(false),
    numberOfColorAttachments: 1,
    isDepthTarget: false,
    width: (sizes) => {
      return Math.floor(sizes.width / Math.pow(2, 3));
    },
    height: (sizes) => {
      return Math.floor(sizes.height / Math.pow(2, 3));
    },
    clear: true,
    textureType: FloatType,
  };
};

let bloomUp3 = () => {
  return {
    name: "bloomUp3",
    type: "QuadPass",
    shader: shaders.BloomUpsample(false),
    numberOfColorAttachments: 1,
    isDepthTarget: false,
    width: (sizes) => {
      return Math.floor(sizes.width / Math.pow(2, 2));
    },
    height: (sizes) => {
      return Math.floor(sizes.height / Math.pow(2, 2));
    },
    clear: true,
    textureType: FloatType,
  };
};

let bloomUp4 = () => {
  return {
    name: "bloomUp4",
    type: "QuadPass",
    shader: shaders.BloomUpsample(false),
    numberOfColorAttachments: 1,
    isDepthTarget: false,
    width: (sizes) => {
      return Math.floor(sizes.width / Math.pow(2, 1));
    },
    height: (sizes) => {
      return Math.floor(sizes.height / Math.pow(2, 1));
    },
    clear: true,
    textureType: FloatType,
  };
};

let bloomUp5 = () => {
  return {
    name: "bloomUp5",
    type: "QuadPass",
    shader: shaders.BloomUpsample(true),
    numberOfColorAttachments: 1,
    isDepthTarget: false,
    width: (sizes) => {
      return Math.floor(sizes.width / Math.pow(2, 0));
    },
    height: (sizes) => {
      return Math.floor(sizes.height / Math.pow(2, 0));
    },
    clear: true,
    textureType: FloatType,
  };
};

let final = () => {
  return {
    name: "final",
    type: "QuadPass",
    shader: shaders.Final,
    numberOfColorAttachments: 1,
    isDepthTarget: false,
    width: (sizes) => {
      return sizes.width;
    },
    height: (sizes) => {
      return sizes.height;
    },
    clear: true,
    textureType: "Final",
  };
};

export {
  gBuffer,
  SSAO,
  shadow,
  tilemaxX,
  tilemaxY,
  neighbourmax,
  light,
  motionblur,
  taaresolve,
  accumulation,
  bloomDown1,
  bloomDown2,
  bloomDown3,
  bloomDown4,
  bloomDown5,
  bloomUp1,
  bloomUp2,
  bloomUp3,
  bloomUp4,
  bloomUp5,
  final,
};
