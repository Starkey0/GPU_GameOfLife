

/*******************************************************************************************
*
*   raylib [core] example - 2d camera
*
*   This example has been created using raylib 1.5 (www.raylib.com)
*   raylib is licensed under an unmodified zlib/libpng license (View raylib.h for details)
*
*   Copyright (c) 2016 Ramon Santamaria (@raysan5)
*
********************************************************************************************/
#include "raylib.h"
#include <string.h>
#include "kernel.h"

cudaError_t evolveWithCuda(unsigned int cells[MAX_GRID_X*MAX_GRID_Y]);

cudaError_t addWithCuda(int* c, const int* a, const int* b, unsigned int size);


int main(void)
{
    // Initialization
    //--------------------------------------------------------------------------------------
    InitWindow(SCREENWIDTH, SCREENHEIGHT, "Game of Life");

    Rectangle player = { SCREENWIDTH / 2, SCREENHEIGHT / 2, 0, 0 };
    unsigned int cells[MAX_GRID_X*MAX_GRID_Y];

    for_all cells[e] = rand() % 100 < 30 ? 0 : 255;

    Camera2D camera = { 0 };
    camera.target = (Vector2){ player.x + CELL_SIZE / 2, player.y + CELL_SIZE / 2 };
    camera.offset = (Vector2){ SCREENWIDTH / 2, SCREENHEIGHT / 2 };
    camera.rotation = 0.0f;
    camera.zoom = 0.9f;

    SetTargetFPS(60);                   // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!WindowShouldClose())        // Detect window close button or ESC key
    {
        // Update
        //----------------------------------------------------------------------------------

        // Player movement
        if (IsKeyDown(KEY_D)) player.x += 20;
        else if (IsKeyDown(KEY_A)) player.x -= 20;

        if (IsKeyDown(KEY_S)) player.y += 20;
        else if (IsKeyDown(KEY_W)) player.y -= 20;

        // Camera target follows player
        camera.target = (Vector2){ player.x + 5, player.y + 5 };

        // Camera rotation controls
        if (IsKeyDown(KEY_Q)) camera.rotation--;
        else if (IsKeyDown(KEY_E)) camera.rotation++;

        // Limit camera rotation to 80 degrees (-40 to 40)
        if (camera.rotation > 40) camera.rotation = 40;
        else if (camera.rotation < -40) camera.rotation = -40;

        // Camera zoom controls
        camera.zoom += ((float)GetMouseWheelMove() * 0.05f);

        if (camera.zoom > 3.0f) camera.zoom = 3.0f;
        else if (camera.zoom < 0.1f) camera.zoom = 0.1f;

        // Camera reset (zoom and rotation)
        if (IsKeyPressed(KEY_R))
        {
            camera.zoom = 1.0f;
            camera.rotation = 0.0f;
        }

        evolveWithCuda(cells);

        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        BeginDrawing();

        ClearBackground(RAYWHITE);

        BeginMode2D(camera);

        for_xy DrawRectangleRec((Rectangle) { x << CELL_POW, y << CELL_POW, CELL_SIZE, CELL_SIZE }, 
            (Color) { cells[x+y* MAX_GRID_X], cells[x+y* MAX_GRID_X], cells[x+y* MAX_GRID_X], 255 });


        EndMode2D();

        EndDrawing();
        //----------------------------------------------------------------------------------
    }


    // De-Initialization
    //--------------------------------------------------------------------------------------
    CloseWindow();        // Close window and OpenGL context
    //--------------------------------------------------------------------------------------

    return 0;
}

