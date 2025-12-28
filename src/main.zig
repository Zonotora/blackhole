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
    // Set the OpenGL viewport to match the new window size
    c.glViewport(0, 0, width, height);
}

fn compileShader(shader_type: c.GLenum, source: [*c]const u8) !c.GLuint {
    // Create a shader object of the specified type (vertex or fragment)
    const shader = c.glCreateShader(shader_type);

    // Attach the GLSL source code to the shader object
    c.glShaderSource(shader, 1, &source, null);

    // Compile the shader source code into GPU instructions
    c.glCompileShader(shader);

    // Check if compilation was successful
    var success: c.GLint = undefined;
    c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        var info_log: [512]u8 = undefined;
        // Retrieve the compilation error log
        c.glGetShaderInfoLog(shader, 512, null, &info_log);
        std.debug.print("Shader compilation failed: {s}\n", .{info_log});
        return error.ShaderCompilationFailed;
    }

    return shader;
}

fn createShaderProgram(vertex_src: [*c]const u8, fragment_src: [*c]const u8) !c.GLuint {
    const vertex_shader = try compileShader(c.GL_VERTEX_SHADER, vertex_src);
    // Delete shader after linking (it's no longer needed as standalone object)
    defer c.glDeleteShader(vertex_shader);

    const fragment_shader = try compileShader(c.GL_FRAGMENT_SHADER, fragment_src);
    defer c.glDeleteShader(fragment_shader);

    // Create a program object that can link multiple shaders together
    const program = c.glCreateProgram();

    // Attach both vertex and fragment shaders to the program
    c.glAttachShader(program, vertex_shader);
    c.glAttachShader(program, fragment_shader);

    // Link the shaders together into a complete GPU program
    c.glLinkProgram(program);

    // Check if linking was successful
    var success: c.GLint = undefined;
    c.glGetProgramiv(program, c.GL_LINK_STATUS, &success);
    if (success == 0) {
        var info_log: [512]u8 = undefined;
        // Retrieve the linking error log
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
    // Clean up program when done
    defer c.glDeleteProgram(shader_program);

    // Rectangle vertices (two triangles)
    const vertices = [_]f32{
        // First triangle
        -1, 1, 0.0, // Top left
        -1, -1, 0.0, // Bottom left
        1, -1, 0.0, // Bottom right

        // Second triangle
        -1, 1, 0.0, // Top left
        1, -1, 0.0, // Bottom right
        1, 1, 0.0, // Top right
    };

    var vao: c.GLuint = undefined;
    var vbo: c.GLuint = undefined;

    // Generate a Vertex Array Object (VAO) - stores vertex attribute configuration
    c.glGenVertexArrays(1, &vao);
    // Generate a Vertex Buffer Object (VBO) - stores actual vertex data
    c.glGenBuffers(1, &vbo);

    // Bind VAO - all subsequent vertex attribute calls will be stored in this VAO
    c.glBindVertexArray(vao);

    // Bind VBO as the current array buffer
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    // Upload vertex data to GPU memory (STATIC_DRAW = data won't change often)
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, c.GL_STATIC_DRAW);

    // Define how OpenGL should interpret the vertex data
    // (location=0, 3 floats per vertex, stride of 3 floats, starting at offset 0)
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), null);
    // Enable the vertex attribute at location 0
    c.glEnableVertexAttribArray(0);

    // Unbind VBO and VAO (good practice to avoid accidental modifications)
    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
    c.glBindVertexArray(0);

    const t = c.glGetUniformLocation(shader_program, "u_time");
    var timer = try std.time.Timer.start();

    // Render loop
    while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        // Set the clear color (background color in RGBA: black)
        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        // Clear the color buffer with the clear color
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        // Activate our shader program for rendering
        c.glUseProgram(shader_program);

        const ns: u64 = timer.read();
        const time_seconds: f32 = @floatCast(@as(f64, @floatFromInt(ns)) / 1_000_000_000.0);

        c.glUniform1f(t, time_seconds);

        // Bind the VAO containing our vertex configuration
        c.glBindVertexArray(vao);
        // Draw 6 vertices as triangles (2 triangles = 1 rectangle)
        c.glDrawArrays(c.GL_TRIANGLES, 0, 6);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }

    // Clean up OpenGL resources
    c.glDeleteVertexArrays(1, &vao);
    c.glDeleteBuffers(1, &vbo);
}
