/// Support for doing something awesome.
///
/// More dartdocs go here.
library dart_webgl_utils;

import 'dart:html';

import 'dart:web_gl';

///
/// Wrapped logging function.
/// msg The message to log.
void error(String msg) {
  window.console.error(msg);
}

/// Loads a shader.
/// gl The WebGLRenderingContext2 to use.
/// shaderSource The shader source.
/// shaderType The type of shader.
/// opt_errorCallback callback for errors.
Shader loadShader(RenderingContext2 gl, String shaderSource, int shaderType,
    {void Function(String) opt_errorCallback}) {
  final errFn = opt_errorCallback ?? error;
  // Create the shader object
  final shader = gl.createShader(shaderType);

  // Load the shader source
  gl.shaderSource(shader, shaderSource);

  // Compile the shader
  gl.compileShader(shader);

  // Check the compile status
  final compiled = gl.getShaderParameter(shader, WebGL.COMPILE_STATUS);
  if (!compiled) {
    // Something went wrong during compilation; get the error
    final lastError = gl.getShaderInfoLog(shader);
    errFn(
        "*** Error compiling shader '" + shader.toString() + "':" + lastError);
    gl.deleteShader(shader);
    return null;
  }

  return shader;
}

/// Creates a program, attaches shaders, binds attrib locations, links the
/// program and calls useProgram.
/// shaders The shaders to attach
/// [opt_attribs] An array of attribs names. Locations will be assigned by index if not passed in
/// [opt_locations] The locations for the. A parallel array to opt_attribs letting you assign locations.
/// opt_errorCallback callback for errors. By default it just prints an error to the console
/// on error. If you want something else pass an callback. It's passed an error message.
Program createProgram(RenderingContext2 gl, Iterable<Shader> shaders,
    {List<String> opt_attribs,
      List<int> opt_locations,
      void Function(String) opt_errorCallback}) {
  final errFn = opt_errorCallback ?? error;
  final program = gl.createProgram();
  shaders.forEach((shader) {
    gl.attachShader(program, shader);
  });
  if (opt_attribs != null) {
    opt_attribs.asMap().forEach((ndx, attrib) {
      gl.bindAttribLocation(
          program, opt_locations != null ? opt_locations[ndx] : ndx, attrib);
    });
  }
  gl.linkProgram(program);

  // Check the link status
  final linked = gl.getProgramParameter(program, WebGL.LINK_STATUS);
  if (!linked) {
    // something went wrong with the link
    final lastError = gl.getProgramInfoLog(program);
    errFn('Error in program linking:' + lastError);

    gl.deleteProgram(program);
    return null;
  }
  return program;
}

/// Loads a shader from a script tag.
/// gl The WebGLRenderingContext2 to use.
/// scriptId The id of the script tag.
/// opt_shaderType The type of shader. If not passed in it will
/// be derived from the type of the script tag.
/// opt_errorCallback callback for errors.
/// The created shader.
Shader createShaderFromScript(RenderingContext2 gl, String scriptId,
    {int opt_shaderType, void Function(String) opt_errorCallback}) {
  var shaderSource = '';
  var shaderType = opt_shaderType;
  final shaderScript = document.getElementById(scriptId) as ScriptElement;
  if (shaderScript == null) {
    throw '*** Error: unknown script element ' + scriptId;
  }
  shaderSource = shaderScript.text;

  if (shaderType == null) {
    if (shaderScript.type == 'x-shader/x-vertex') {
      shaderType = WebGL.VERTEX_SHADER;
    } else if (shaderScript.type == 'x-shader/x-fragment') {
      shaderType = WebGL.FRAGMENT_SHADER;
    } else if (shaderType != WebGL.VERTEX_SHADER &&
        shaderType != WebGL.FRAGMENT_SHADER) {
      throw '*** Error: unknown shader type';
    }
  }

  return loadShader(gl, shaderSource, shaderType,
      opt_errorCallback: opt_errorCallback);
}

const defaultShaderType = <int>[WebGL.VERTEX_SHADER, WebGL.FRAGMENT_SHADER];

/// Creates a program from 2 script tags.
///
/// gl The WebGLRenderingContext2 to use.
/// shaderScriptIds Array of ids of the script
/// tags for the shaders. The first is assumed to be the
/// vertex shader, the second the fragment shader.
/// [opt_attribs] An array of attribs names. Locations will be assigned by index if not passed in
/// [opt_locations] The locations for the. A parallel array to opt_attribs letting you assign locations.
/// opt_errorCallback callback for errors. By default it just prints an error to the console
/// on error. If you want something else pass an callback. It's passed an error message.
Program createProgramFromScripts(
    RenderingContext2 gl, List<String> shaderScriptIds,
    {List<String> opt_attribs,
      List<int> opt_locations,
      void Function(String) opt_errorCallback}) {
  final shaders = <Shader>[];
  for (var ii = 0; ii < shaderScriptIds.length; ++ii) {
    shaders.add(createShaderFromScript(gl, shaderScriptIds[ii],
        opt_shaderType: defaultShaderType[ii],
        opt_errorCallback: opt_errorCallback));
  }
  return createProgram(gl, shaders,
      opt_attribs: opt_attribs,
      opt_locations: opt_locations,
      opt_errorCallback: opt_errorCallback);
}

///
/// Creates a program from 2 sources.
///
/// gl The WebGLRenderingContext2 to use.
/// shaderSourcess Array of sources for the
/// shaders. The first is assumed to be the vertex shader,
/// the second the fragment shader.
/// [opt_attribs] An array of attribs names. Locations will be assigned by index if not passed in
/// [opt_locations] The locations for the. A parallel array to opt_attribs letting you assign locations.
/// opt_errorCallback callback for errors. By default it just prints an error to the console
/// on error. If you want something else pass an callback. It's passed an error message.
Program createProgramFromSources(
    RenderingContext2 gl, List<String> shaderSources,
    {List<String> opt_attribs,
      List<int> opt_locations,
      void Function(String) opt_errorCallback}) {
  final shaders = <Shader>[];
  for (var ii = 0; ii < shaderSources.length; ++ii) {
    shaders.add(loadShader(gl, shaderSources[ii], defaultShaderType[ii],
        opt_errorCallback: opt_errorCallback));
  }
  return createProgram(gl, shaders,
      opt_attribs: opt_attribs,
      opt_locations: opt_locations,
      opt_errorCallback: opt_errorCallback);
}

/// Resize a canvas to match the size its displayed.
/// canvas The canvas to resize.
/// [multiplier] amount to multiply by.
/// Pass in window.devicePixelRatio for native pixels.
bool resizeCanvasToDisplaySize(CanvasElement canvas, {int multiplier = 1}) {
  final width = (canvas.clientWidth * multiplier).floor();
  final height = (canvas.clientHeight * multiplier.floor());
  if (canvas.width != width || canvas.height != height) {
    canvas.width = width;
    canvas.height = height;
    return true;
  }
  return false;
}
