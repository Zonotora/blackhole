const std = @import("std");

const c = @cImport({
    @cDefine("GL_GLEXT_PROTOTYPES", {});
    @cInclude("GLFW/glfw3.h");
});

const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 600;

const vertex_shader_source = @embedFile("shaders/vertex.glsl");
const fragment_shader_source = @embedFile("shaders/fragment.glsl");

fn errorCallback(_: c_int, description: [*c]const u8) callconv(.c) void {
    std.debug.print("GLFW Error: {s}\n", .{description});
}

fn framebufferSizeCallback(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.c) void {
    c.glViewport(0, 0, width, height);
}

fn compileShader(shader_type: c.GLenum, source: [*c]const u8) !c.GLuint {
    const shader = c.glCreateShader(shader_type);
    c.glShaderSource(shader, 1, &source, null);
    c.glCompileShader(shader);

    var success: c.GLint = undefined;
    c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        var info_log: [512]u8 = undefined;
        c.glGetShaderInfoLog(shader, 512, null, &info_log);
        std.debug.print("Shader compilation failed: {s}\n", .{info_log});
        return error.ShaderCompilationFailed;
    }

    return shader;
}

fn createShaderProgram(vertex_src: [*c]const u8, fragment_src: [*c]const u8) !c.GLuint {
    const vertex_shader = try compileShader(c.GL_VERTEX_SHADER, vertex_src);
    defer c.glDeleteShader(vertex_shader);

    const fragment_shader = try compileShader(c.GL_FRAGMENT_SHADER, fragment_src);
    defer c.glDeleteShader(fragment_shader);

    const program = c.glCreateProgram();
    c.glAttachShader(program, vertex_shader);
    c.glAttachShader(program, fragment_shader);
    c.glLinkProgram(program);

    var success: c.GLint = undefined;
    c.glGetProgramiv(program, c.GL_LINK_STATUS, &success);
    if (success == 0) {
        var info_log: [512]u8 = undefined;
        c.glGetProgramInfoLog(program, 512, null, &info_log);
        std.debug.print("Shader program linking failed: {s}\n", .{info_log});
        return error.ProgramLinkingFailed;
    }

    return program;
}

pub fn main() !void {
    _ = c.glfwSetErrorCallback(errorCallback);

    if (c.glfwInit() == c.GLFW_FALSE) {
        std.debug.print("Failed to initialize GLFW\n", .{});
        return error.GLFWInitFailed;
    }
    defer c.glfwTerminate();

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);

    const window = c.glfwCreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "OpenGL Rectangle", null, null);
    if (window == null) {
        std.debug.print("Failed to create GLFW window\n", .{});
        return error.WindowCreationFailed;
    }
    defer c.glfwDestroyWindow(window);

    c.glfwMakeContextCurrent(window);
    _ = c.glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);

    const shader_program = try createShaderProgram(vertex_shader_source, fragment_shader_source);
    defer c.glDeleteProgram(shader_program);

    // Rectangle vertices (two triangles)
    const vertices = [_]f32{
        // First triangle
        -0.5, 0.5, 0.0, // Top left
        -0.5, -0.5, 0.0, // Bottom left
        0.5, -0.5, 0.0, // Bottom right

        // Second triangle
        -0.5, 0.5, 0.0, // Top left
        0.5, -0.5, 0.0, // Bottom right
        0.5, 0.5, 0.0, // Top right
    };

    var vao: c.GLuint = undefined;
    var vbo: c.GLuint = undefined;

    c.glGenVertexArrays(1, &vao);
    c.glGenBuffers(1, &vbo);

    c.glBindVertexArray(vao);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, c.GL_STATIC_DRAW);

    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), null);
    c.glEnableVertexAttribArray(0);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
    c.glBindVertexArray(0);

    // Render loop
    while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glUseProgram(shader_program);
        c.glBindVertexArray(vao);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 6);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }

    c.glDeleteVertexArrays(1, &vao);
    c.glDeleteBuffers(1, &vbo);
}
