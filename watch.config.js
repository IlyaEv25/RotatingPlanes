module.exports = {
  watch: true,
  devtool: "source-map",

  module: {
    rules: [
      {
        test: /\.glslf$/,
        loader: "webpack-glsl-loader",
      },
      {
        test: /\.glslv$/,
        loader: "webpack-glsl-loader",
      },
      {
        test: /\.(png|jpe?g|gif)$/i,
        loader: "file-loader",
        options: {
          name: "[name].[ext]",
          outputPath: "./textures/",
          publicPath: "./textures/",
        },
      },
    ],
  },
  };
  