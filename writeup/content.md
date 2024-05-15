# Audio Reactive Visualizations Using Machine Learning and a Custom Raymarching GPU

*By Michael Crum (mmc323) and Antti Meriluoto (ahm234)*


## Introduction

In a tradition as old as time, sights and sounds are often paired together to induce emotion in the observer.
Incredible reactions can be created with careful pairings of the two, although the exact relation between image and audio is, as with many things distinctly human, difficult to pin down precisely.
Of course, this difficulty only seems to make the challenge more appealing to creatives, scientists, and all varieties of people in between.

For our final project, we chose to attempt a unique approach to the problem, utilizing the skills and tools we learned during the class to create visual interpretations of songs.
We used machine learning to extract emotional meaning from the music, which in turn impacted the ray marched visuals generated on the FPGA.
In this write-up, we will summarize the various techniques used to realize our final product.


## Results

Although it’s somewhat unconventional to show results at the beginning of the write-up, seeing the final product might help you visualize what we’re going on about in the following sections.

_I’ll insert pictures/videos here in the final website_

## Sentiment Analysis

_section in progress_


## FPGA-Based Raymarching GPU


### Background


#### The ray marching algorithm

For brevity, this section will offer an abridged description of the raymarching algorithm.
If you wish to learn more about the algorithm, Michael [has written a full article about it on his website](https://michael-crum.com/raymarching/) (with pretty demos too!).

Raymarching is a form of [physically based rendering](https://en.wikipedia.org/wiki/Physically_based_rendering): rendering techniques that model the interaction of lights and physical objects to emulate real-world vision.
Because emulating billions of photons emitted from light sources is intractable, physically based rendering techniques instead work backward to trace the path of photons that ultimately end up hitting the camera (or eye, depending on how you prefer to think of it).

At a base level, the goal of rendering is to assign a color to each screen pixel.
Think of your screen as a window.
Through the window is the scene we wish to render, made up of simple shapes.
The screen/window can be quantized by its pixels, each specifying a unique coordinate on the window.
For light from the scene to enter your eye, it must pass through one of these pixels in the window.
Suppose we calculate the vector from your eye through each pixel on the window.
We can then use this vector to work backward and determine information about the photons that would enter through that pixel.
From this information, we can determine the color of that pixel.
Figure X visualizes this process for one pixel.

![alt_text](./assets/image_plane.png)

_Figure X: From pixels to rays (Credit: [Michael Walczyk](https://michaelwalczyk.com/blog-ray-marching.html))_

The process is well-researched in computer graphics and is computed using the inverse [camera projection matrix](https://en.wikipedia.org/wiki/Camera_matrix).
For our virtual camera, this operation boils down to just a couple of operations:

```
vec2 xy = coordinate.xy - resolution.xy / 2.0;
float z = resolution.y / tan(radians(field_of_view) / 2.0);
vec3 view_direction = normalize(vec3(xy, -z));
```

With per-pixel rays calculated, we can begin tracing them backward into the scene.
The first challenge is determining where a ray intersects the scene.
One approach is to analytically compute the ray-scene intersection.
This is the basis of ray tracing, but this computation is expensive and scales poorly with the scene's complexity.
For use on the resource-constrained FPGA, we need to be a bit more clever.

Enter ray marching, an iterative solution for computing ray-scene intersections.
The key abstraction of the ray marching algorithm is the signed distance field (SDF).
An SDF is a function that takes in a point in space and returns the distance from the point to a scene.
To illustrate the concept I will use 2D SDFs, but they trivially extend to 3D space.
The simplest 2D SDF is a circle located at the origin.
The calculation is trivial:

```

return length(point) - radius;

```

Such distance functions exist for all manner of primitives, both 2D and 3D (see Figure X).

![alt_text](./assets/2d_sdf.webp)


_Figure X: Raymarched primitives_

Ray marching leverages SDFs to know how far it can **safely** step along a ray without intersecting with the scene.
The process is as follows:

1. Set point $p$ at the camera origin.
2. Evaluate SDF to find minimum distance $d$ from the scene.
    1. If $d < \epsilon$ (some small number), you’ve hit the scene
    2. Else continue
3. Step $d$ units along the ray, ie $p += ray * d$
4. Goto 1

It's important to notice that step 3 is **guaranteed** to not set $p$ inside of an object.
Because $p$ starts in free space, and $d$ is the minimum distance to the scene along _any_ direction, stepping along _any ray by $d$ will cause the new distance to be >= 0.
If the ray does intersect with the scene, $d$ will converge to zero, and the algorithm will register the point as an intersection.
Figure X illustrates the algorithm on a 2D scene.
Each blue point is $p$ after some number of iterations, and each circle represents $d$ evaluated at $p$ for each iteration.

<iframe src="https://michael-crum.com/ThreeJS-Raymarcher/2d_demo.html" title="2D Demo" style="visibility: visible;"></iframe>

_Figure X: 2D ray marching demo_

SDFs of multiple objects can be combined simply by taking the minimum of their individual SDFs.
Similar operations exist for intersection and difference.
SDFs can also be deformed to scale, rotate, twist, and repeat the SDF throughout space.
I won’t go over all of the operations here, but I’ll leave[ this excellent reference on the topic](https://iquilezles.org/articles/distfunctions/).

Ray marching outperforms ray tracing in situations where SDFs are more efficient to compute than analytic intersections.
Being an iterative solution, it is also well suited to be broken up into multiple clock cycles on the FPGA.
Notice also that each pixel is computed completely independently, perfect for massive parallelization.
This is the exact purpose of a GPU and the reason they are so valuable for graphical applications.


#### Floating point and vector math on an FPGA

To have any hope at running the ray marching algorithm, we need a fractional representation that will run on the FPGA.
The traditional solution to this problem is using a fixed-point representation, but this comes with trade-offs either in magnitude or precision.
Because ray marching operates over a wide range of magnitudes, fixed-point was off the table.
We instead decided to use the [1.8.18 floating-point implementation](https://people.ece.cornell.edu/land/courses/ece5760/DE1_SOC/HPS_peripherials/Floating_Point_index.html) written by past students and improved by Bruce Land.
This gives an impressive range both for low-magnitude precision, important for normalized vectors, and high-magnitude representation, important for rendering objects at long range.

To simplify many repeated operations in our Verilog, we wrote a vector math library utilizing floating point math.
The library can be found in vector_ops.v in the appendix and includes dot products, scalar multiplication, addition, and 3x3 matrix multiplication.


### Prototyping and verification

Before launching into a full Verilog implementation, we created a reference implementation in GLSL (OpenGL Shading Language).
GLSL is a C-like language specifically for writing shaders (programs that run per pixel on the GPU).
The GLSL implementation is only 100 lines and can be found in the appendix under fractal frag.
We used this reference implementation to render the Serpinski pyramid fractal (Figure X).

![Serpinski Pyramid](./assets/serpinski.png)


_Figure X: Serpinski pyramid rendered with GLSL_

After verifying the GLSL design, we moved on to Verilog.
Because compiling code for the FPGA takes many minutes, we looked for a simulation tool that could show VGA output without lengthy Quartus compile times.
We found the tool [Verilator](https://verilator.org/guide/latest/), which compiles Verilator source code into multithreaded C++ object files.
The Verilated source code can then be linked against and the output of the model can be passed into any C++ functions of our choosing.
We used [SDL](https://github.com/libsdl-org/SDL) to render the output VGA of our model directly to a screen buffer, which can then be rendered into a window.
This [webpage from Project F](https://projectf.io/posts/verilog-sim-verilator-sdl/) was a great resource for setting up the system.
Simulating this way allowed us to render 2-3 frames per second, far from real-time but many times faster than a full Quartus compile.
Using this strategy we were able to quickly iterate on the design and fix bugs many times more efficiently than in previous labs.
See Figure X for an example of Verilated VGA output.

![Verilated VGA output](./assets/verilated_vga.png)

_Figure X: Output of Verilated model rendered with SDL_


### Architecture

Our ray-marching GPU uses a pipeline architecture to concurrently calculate dozens of pixels simultaneously.
The first step for any pixel is calculating its corresponding ray using the equations detailed in the background section.
From there, the pixel and ray components are passed into the first ray-marching core.
Each ray marching core is responsible for one iteration of the ray marching algorithm.
Because the algorithm itself takes up multiple clock cycles and the SDF evaluation can take up many more, the entire core operates as a long pipeline.
One pixel/ray combo is passed in per clock cycle, and, once per clock cycle, the core spits out the same pixel and ray information coupled with a new value of $p$.
The cores can be chained together to achieve multiple stages of iteration per clock cycle.

![Simplified pipeline architecture](./assets/pipeline_architecture.svg)

_Figure X: Simplified pipeline architecture_

The number of cores that can be chained together is dependent on the available hardware on the FPGA.
Because calculating more complicated SDFs takes additional hardware, the number of stages is also inversely proportional to the complexity of the scene.
For simple scenes (e.g. a single cube), up to six cores can be chained together.
This drops to three or even two for more interesting scenes and quickly becomes detrimental to the quality of the rendering.
Truthfully, even a six-iteration ray marcher offers subpar rendering results, as shown in figure X.

![](./assets/maybe_a_cube.jpg)

_Figure X: A "cube" rendered with six iterations_

To do better the architecture must be revised to allow pixels to reenter the pipeline if they need further refinement.
With this strategy, each pixel/ray is evaluated in the last core to see if it has intersected the scene.
If it has, a new pixel is pushed into the pipeline and a global pixel index is incremented to represent the next pixel in line.
If it has not intersected with the scene yet, it is fed back into the first core, and the pixel index is not incremented.
This way pixels can take multiple rides through the pipeline according to their needs.

![Updated pipeline architecture](./assets/updated_pipeline_architecture.svg)

_Figure X: Updated pipeline architecture_

This architecture provides an unbounded number of iterations to the pixels that need them, allowing for much crisper and more detailed renders.
It also provides a variable refresh rate, where low-effort pixels can continue getting rerendered while high-effort pixels render more slowly in the background.
This gives the illusion of snappy responsiveness during camera movement while allowing for high detail on close inspection.
As a final benefit, it allows for rendering high-complexity scenes that would otherwise require too many resources to render in a single pipeline.


## Implementation

### Handling Pipelines Without Going Insane

The floating point library I used requires two cycles for a floating point add and five cycles for an inverse square root.
This introduced pipelining requirements all over the project in order to keep relevant data available at the correct cycle.
Hand writing each pipeline stage would be infurating and error prone, so we adopted a system that to handle pipeline registers for us using generate statements. As an example:

```
module FP_sqrt #(
    parameter PIPELINE_STAGES = 4
) (
    input i_clk,
    input [26:0] i_a,
    output [26:0] o_sqrt
);
    wire [26:0] inv_sqrt;
    reg  [26:0] i_a_pipe [PIPELINE_STAGES:0];
    FpInvSqrt inv_sq (
        .iCLK(i_clk),
        .iA(i_a),
        .oInvSqrt(inv_sqrt)
    );
    FpMul recip (
        .iA(inv_sqrt),
        .iB(i_a_pipe[PIPELINE_STAGES]),
        .oProd(o_sqrt)
    );
    genvar i;
    generate
        for (i = 0; i < PIPELINE_STAGES; i = i + 1) begin : g_ray_pipeline
            always @(posedge i_clk) begin
                i_a_pipe[0] = i_a;
                i_a_pipe[i+1] <= i_a_pipe[i];
            end
        end
    endgenerate
endmodule
```

This snippet creates a series of pipeline registers of length `PIPELINE_STAGES`, and pushes data through the pipeline on each clock cycle.
This is required because input `i_a` will be updated every cycle, and will have a new value by the time `FpInvSqrt`'s output becomes valid for use in the multiply.
This snippet is a trivial example, but the system was crucial for other parts of the code that must pipeline up to ten diffent values.

### Pixel to Ray

As mentioned in the background section, a the ray corresponding to a pixel can be calculated in the following way:

```
vec2 xy = coordinate.xy - resolution.xy / 2.0;
float z = resolution.y / tan(radians(field_of_view) / 2.0);
vec3 ray = normalize(vec3(xy, -z));
```

This assumes a camera that always looks straight forward, however, which is a bit boring. To spice things up, we added a [look at matrix](https://medium.com/@carmencincotti/lets-look-at-magic-lookat-matrices-c77e53ebdf78). Because the camera movement will be computed on the HPS, we computed the matrix in C and transfered it over PIO to the FPGA.

```
vec2 xy = coordinate.xy - resolution.xy / 2.0;
float z = resolution.y / tan(radians(FIELD_OF_VIEW) / 2.0);
vec3 ray = lookAt(
    -camera_pos,
    vec3(0.0, 0.0, 0.0),
    vec3(0.0, 1.0, 0.0)
) * normalize(vec3(xy, -z));
```

At first glance these operations seem intimidating the execute on an FPGA, specifically the divisions and tan operation.
However, `resolution` and `field_of_view` are both constant, so anything involving them can be precomputed. In fact, the entire `z` assignment boils down to a constant.
All other operations are linear, and can be computed with the vector math library we created. Calculating a ray takes 9 cycles, but is pipelined. Here's what the operation looks like in Verilog:

```
wire signed [`CORDW:0] x_signed, y_signed, x_adj, y_adj;
assign x_signed = {1'b0, i_x};
assign y_signed = {1'b0, i_y};

assign x_adj = x_signed - (`SCREEN_WIDTH >> 1);
assign y_adj = y_signed - (`SCREEN_HEIGHT >> 1);
wire [26:0] x_fp, y_fp, z_fp, res_x_fp, res_y_fp;
Int2Fp px_fp (
    .iInteger({{5{x_adj[`CORDW]}}, x_adj[`CORDW:0]}),
    .oA(x_fp)
);
Int2Fp py_fp (
    .iInteger({{5{y_adj[`CORDW]}}, y_adj[`CORDW:0]}),
    .oA(y_fp)
);
Int2Fp calc_res_x_fp (
    .iInteger(`SCREEN_WIDTH),
    .oA(res_x_fp)
);
Int2Fp calc_res_y_fp (
    .iInteger(`SCREEN_HEIGHT),
    .oA(res_y_fp)
);
FpMul z_calc (
    .iA(res_y_fp),
    .iB(`FOV_MAGIC_NUMBER),
    .oProd(z_fp)
);
wire [26:0] x_norm_fp, y_norm_fp, z_norm_fp;
VEC_normalize hi (
    .i_clk(i_clk),
    .i_x(x_fp),
    .i_y(y_fp),
    .i_z(z_fp),
    .o_norm_x(x_norm_fp),
    .o_norm_y(y_norm_fp),
    .o_norm_z(z_norm_fp)
);
wire [26:0] z_neg_fp;
FpNegate negate_z (
    .iA(z_norm_fp),
    .oNegative(z_neg_fp)
);
VEC_3x3_mult oh_god (
    .i_clk(i_clk),
    .i_m_1_1(look_at_1_1),
    .i_m_1_2(look_at_1_2),
    .i_m_1_3(look_at_1_3),
    .i_m_2_1(look_at_2_1),
    .i_m_2_2(look_at_2_2),
    .i_m_2_3(look_at_2_3),
    .i_m_3_1(look_at_3_1),
    .i_m_3_2(look_at_3_2),
    .i_m_3_3(look_at_3_3),
    .i_x(x_norm_fp),
    .i_y(y_norm_fp),
    .i_z(z_neg_fp),
    .o_x(o_x),
    .o_y(o_y),
    .o_z(o_z)
);
```

### Ray marching core



### SDFs

### Color calculation and the VGA driver

## Details

With the floating point and vector math libraries implemented, the Verilog was largely the same as the GLSL, with the major exceptions of pipeline and display buffer handling.

Pipelining refers to breaking up a complex operation into steps that can be spread out over multiple clock cycles.
Each step runs independently, however, and each step can be busy working on a different input at the same time.
This means that data is output as quickly as it is input, save for a delay for the first input to reach the end of the pipeline.

While writing pipelined code, synchronization is extremely important.
Imagine we have some function, add(), that takes a clock cycle to complete.
You additionally have three inputs, x, y, and z.
To sum the three numbers, you may naively write:

```

a = add(x, y)

b = add(a, z)

```

However, this will give you the wrong result.
Let $x_n$ represent the input for variable x on clock cycle n.
On clock cycle 2, a will be the sum of x<sub>1</sub> and y<sub>1</sub> because of the latency the add function creates.
However, z will be z<sub>2</sub>, the input from the current cycle, resulting in b being the sum of x<sub>1</sub>, y<sub>1, </sub>and z<sub>2</sub>.
If the pipeline is being used efficiently, z<sub>1</sub> is not equal to z<sub>2</sub> and the operation will fail.
Instead, a pipeline register for z must be introduced to artificially keep z at the same pace as x and y.

In the code for the GPU, you will often see blocks that look like this:

```
reg [9:0] pixel_x_pipe[PIPELINE_STAGES:0], pixel_y_pipe[PIPELINE_STAGES:0];

always @(posedge clk) begin

    pixel_x_pipe[0] <= pixel_x;

    pixel_y_pipe[0] <= pixel_y;

end

genvar i;

generate

    for (i = 0; i < PIPELINE_STAGES; i = i + 1) begin : g_ray_pipeline

        always @(posedge clk) begin

            pixel_x_pipe[i+1] <= pixel_x_pipe[i];

            pixel_y_pipe[i+1] <= pixel_y_pipe[i];

         end

    end

endgenerate
```

We use these blocks to generate pipeline registers of a length controlled by the PIPELINE_STAGES parameter.
The code can then write and read values from the registers at relevant pipeline latencies.
This greatly reduces the mental overhead associated with keeping track of pipeline synchronization and allows us to debug the pipeline length by tweaking a single value.

For the display buffer, we utilized M10K memory to hold a 10 bit color representation for each pixel.

The other details in the code are better explained through the detailed comments we’ve left in the codebase, which can be found on [Michael’s GitHub page](https://github.com/usedhondacivic/fractal_gpu).


### Bugs, issues, and future work
