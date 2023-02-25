let DeferedMotionBlurTAAPipeline = {
  pipe: ["gBuffer", "tilemaxY", "tilemaxX", "neighbourmax", "SSAO", "light", "taaresolve", "accumulation", "motionblur", "final"],

  dependencies: {
    gBuffer: [],

    SSAO: [
      {
        pass: "gBuffer",
        type: "color",
        uniform: "u_normal",
        channel: 1,
      },
      {
        pass: "gBuffer",
        type: "depth",
        uniform: "u_depth",
        channel: 0,
      },
    ],


    light: [
      {
        pass: "gBuffer",
        type: "color",
        uniform: "u_color",
        channel: 0,
      },
      {
        pass: "gBuffer",
        type: "color",
        uniform: "u_normal",
        channel: 1,
      },

      {
        pass: "gBuffer",
        type: "depth",
        uniform: "u_depth",
        channel: 0,
      },

      {
        pass: "SSAO",
        type: "color",
        uniform: "u_ssao_mask",
        channel: 0,
      },
    ],

    tilemaxY: [
      {
        pass: "gBuffer",
        type: "color",
        uniform: "u_velocity",
        channel: 2,
      },
    ],

    tilemaxX: [
      {
        pass: "tilemaxY",
        type: "color",
        uniform: "u_velocity",
        channel: 0,
      },
    ],

    neighbourmax: [
      {
        pass: "tilemaxX",
        type: "color",
        uniform: "u_tile",
        channel: 0,
      },
    ],

    motionblur: [
      {
        pass: "neighbourmax",
        type: "color",
        uniform: "u_neighbour",
        channel: 0,
      },
      {
        pass: "gBuffer",
        type: "color",
        uniform: "u_velocity",
        channel: 2,
      },
      {
        pass: "taaresolve",
        type: "depth",
        uniform: "u_depth",
        channel: 0,
      },
      {
        pass: "taaresolve",
        type: "color",
        uniform: "u_color",
        channel: 0,
      },
    ],

    taaresolve: [
      {
        pass: "gBuffer",
        type: "color",
        uniform: "u_velocity",
        channel: 2,
      },

      {
        pass: "gBuffer",
        type: "depth",
        uniform: "u_depth",
        channel: 0,
      },

      {
        pass: "accumulation",
        type: "color",
        uniform: "u_accumulated_color",
        channel: 0,
      },

      {
        pass: "accumulation",
        type: "depth",
        uniform: "u_accumulated_depth",
        channel: 0,
      },

      {
        pass: "light",
        type: "color",
        uniform: "u_color",
        channel: 0,
      },
    ],

    accumulation: [
      {
        pass: "taaresolve",
        type: "color",
        uniform: "u_color",
        channel: 0,
      },
      {
        pass: "taaresolve",
        type: "depth",
        uniform: "u_depth",
        channel: 0,
      },
    ],

    final: [
      {
        pass: "motionblur",
        type: "color",
        uniform: "u_color",
        channel: 0,
      },
    ],
  },
};

let DeferedMotionBlurBloomTAAPipeline = {
  pipe: [
    "gBuffer",
    "tilemaxY",
    "tilemaxX",
    "neighbourmax",
    "SSAO",
    "light",
    "bloomDown1",
    "bloomDown2",
    "bloomDown3",
    "bloomDown4",
    "bloomDown5",
    "bloomUp1",
    "bloomUp2",
    "bloomUp3",
    "bloomUp4",
    "bloomUp5",
    "taaresolve",
    "accumulation",
    "motionblur",
    "final",
  ],

  dependencies: {
    gBuffer: [],

    SSAO: [
      {
        pass: "gBuffer",
        type: "color",
        uniform: "u_normal",
        channel: 1,
      },
      {
        pass: "gBuffer",
        type: "depth",
        uniform: "u_depth",
        channel: 0,
      },
    ],

    light: [
      {
        pass: "gBuffer",
        type: "color",
        uniform: "u_color",
        channel: 0,
      },
      {
        pass: "gBuffer",
        type: "color",
        uniform: "u_normal",
        channel: 1,
      },

      {
        pass: "gBuffer",
        type: "depth",
        uniform: "u_depth",
        channel: 0,
      },

      {
        pass: "SSAO",
        type: "color",
        uniform: "u_ssao_mask",
        channel: 0,
      },
    ],

    bloomDown1: [
      {
        pass: "light",
        type: "color",
        uniform: "u_previous",
        channel: 0,
      },
    ],

    bloomDown2: [
      {
        pass: "bloomDown1",
        type: "color",
        uniform: "u_previous",
        channel: 0,
      },
    ],

    bloomDown3: [
      {
        pass: "bloomDown2",
        type: "color",
        uniform: "u_previous",
        channel: 0,
      },
    ],

    bloomDown4: [
      {
        pass: "bloomDown3",
        type: "color",
        uniform: "u_previous",
        channel: 0,
      },
    ],

    bloomDown5: [
      {
        pass: "bloomDown4",
        type: "color",
        uniform: "u_previous",
        channel: 0,
      },
    ],

    bloomUp1: [
      {
        pass: "bloomDown5",
        type: "color",
        uniform: "u_previous",
        channel: 0,
      },
      {
        pass: "bloomDown4",
        type: "color",
        uniform: "u_background",
        channel: 0,
      },
    ],

    bloomUp2: [
      {
        pass: "bloomUp1",
        type: "color",
        uniform: "u_previous",
        channel: 0,
      },
      {
        pass: "bloomDown3",
        type: "color",
        uniform: "u_background",
        channel: 0,
      },
    ],

    bloomUp3: [
      {
        pass: "bloomUp2",
        type: "color",
        uniform: "u_previous",
        channel: 0,
      },
      {
        pass: "bloomDown2",
        type: "color",
        uniform: "u_background",
        channel: 0,
      },
    ],

    bloomUp4: [
      {
        pass: "bloomUp3",
        type: "color",
        uniform: "u_previous",
        channel: 0,
      },
      {
        pass: "bloomDown1",
        type: "color",
        uniform: "u_background",
        channel: 0,
      },
    ],

    bloomUp5: [
      {
        pass: "bloomUp4",
        type: "color",
        uniform: "u_previous",
        channel: 0,
      },
      {
        pass: "light",
        type: "color",
        uniform: "u_background",
        channel: 0,
      },
    ],

    tilemaxY: [
      {
        pass: "gBuffer",
        type: "color",
        uniform: "u_velocity",
        channel: 2,
      },
    ],

    tilemaxX: [
      {
        pass: "tilemaxY",
        type: "color",
        uniform: "u_velocity",
        channel: 0,
      },
    ],

    neighbourmax: [
      {
        pass: "tilemaxX",
        type: "color",
        uniform: "u_tile",
        channel: 0,
      },
    ],

    motionblur: [
      {
        pass: "neighbourmax",
        type: "color",
        uniform: "u_neighbour",
        channel: 0,
      },
      {
        pass: "gBuffer",
        type: "color",
        uniform: "u_velocity",
        channel: 2,
      },
      {
        pass: "taaresolve",
        type: "depth",
        uniform: "u_depth",
        channel: 0,
      },
      {
        pass: "taaresolve",
        type: "color",
        uniform: "u_color",
        channel: 0,
      },
    ],

    taaresolve: [
      {
        pass: "gBuffer",
        type: "color",
        uniform: "u_velocity",
        channel: 2,
      },

      {
        pass: "gBuffer",
        type: "depth",
        uniform: "u_depth",
        channel: 0,
      },

      {
        pass: "accumulation",
        type: "color",
        uniform: "u_accumulated_color",
        channel: 0,
      },

      {
        pass: "accumulation",
        type: "depth",
        uniform: "u_accumulated_depth",
        channel: 0,
      },

      {
        pass: "bloomUp5",
        type: "color",
        uniform: "u_color",
        channel: 0,
      },
    ],

    accumulation: [
      {
        pass: "taaresolve",
        type: "color",
        uniform: "u_color",
        channel: 0,
      },
      {
        pass: "taaresolve",
        type: "depth",
        uniform: "u_depth",
        channel: 0,
      },
    ],

    final: [
      {
        pass: "motionblur",
        type: "color",
        uniform: "u_color",
        channel: 0,
      },
    ],
  },
};

export { DeferedMotionBlurTAAPipeline, DeferedMotionBlurBloomTAAPipeline };
