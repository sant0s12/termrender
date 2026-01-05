# Performance Improvements

This document describes the performance optimizations made to the termrender codebase.

## Summary of Optimizations

### 1. Collision Detection Algorithm - O(n²) to O(n²/2)

**Issue**: The collision detection system was checking every object against every other object, including duplicate checks (A vs B and B vs A).

**Solution**: 
- Changed from checking all objects against all objects to only checking each pair once
- Used indexed iteration to check only objects after the current one: `self.gameObjects.items[i + 1 ..]`
- Cached the transformed bounding box outside the inner loop to avoid recalculating it

**Impact**: 
- Reduced collision checks by ~50% for n objects
- Eliminated redundant BBox transformations (from 2n² to n²)
- Example: With 10 objects, reduced from 100 checks to 45 checks

**Location**: `src/main.zig` - `GameState.tick()` method (lines 28-52)

### 2. Terminal I/O Batching

**Issue**: Each character was written to the terminal with a separate ANSI escape sequence, causing many small write operations. Each call to `drawSingle()` immediately wrote to stdout.

**Solution**:
- Added a write buffer (`std.ArrayList(u8)`) to `TermBuffer`
- Changed `drawSingle()` to append to buffer instead of immediate write
- Added `flush()` method to write entire buffer at once
- Called `flush()` once per frame after all drawing is complete

**Impact**:
- Reduced system calls from N (number of characters) to 1 per frame
- Improved rendering performance by batching all terminal output
- More efficient use of terminal I/O
- Example: Drawing 100 characters now makes 1 write call instead of 100

**Location**: 
- `src/TermBuffer.zig` - Added `write_buffer`, modified `drawSingle()`, added `flush()`
- `src/main.zig` - Added `buffer.flush()` call after drawing (line 133)

### 3. Removed Dead Code

**Issue**: Several methods were defined but never used, adding unnecessary overhead:
- `Drawable.intersect()` vtable method - defined but always returned null
- `Player.intersect()` and `Box.intersect()` - implementations that did nothing
- `GameState.getObjectAt()` - unused method with undefined behavior (called non-existent `intersect` method)

**Solution**:
- Removed `intersect` from the Drawable vtable
- Removed all `intersect()` method implementations
- Removed the unused `getObjectAt()` method

**Impact**:
- Cleaner code with less complexity
- Reduced vtable size
- Eliminated dead code paths

**Location**: 
- `src/Drawable.zig` - Removed intersect from VTable and method
- `src/game_objects/Player.zig` - Removed intersect method
- `src/game_objects/Box.zig` - Removed intersect method
- `src/main.zig` - Removed getObjectAt method

### 4. Fixed Double Gravity Application

**Issue**: In `Box.tick()`, gravity was being applied twice:
```zig
self.speed[1] += self.acceleration[1] + self.gravity;
```
This caused boxes to fall too fast.

**Solution**: Changed to apply gravity only once:
```zig
self.speed[1] += self.gravity;
```

**Impact**:
- Fixed physics bug
- Corrected behavior matches Player physics
- More predictable object movement

**Location**: `src/game_objects/Box.zig` - `tick()` method (line 51)

## Memory Management

The buffering optimization required adding an allocator to TermBuffer:
- Buffer uses `std.ArrayList(u8)` which grows as needed
- Buffer capacity is retained between frames with `clearRetainingCapacity()`
- Proper cleanup with `defer buffer.deinit()` in main

## Testing Recommendations

To verify these optimizations:

1. **Collision Detection**: Add many game objects (10+) and verify smooth performance
2. **Terminal I/O**: Monitor system calls with `strace` - should see single write() calls per frame
3. **Physics**: Verify boxes and player fall at expected rates with correct gravity

## Future Optimization Opportunities

1. **Spatial Partitioning**: For many objects (100+), consider a spatial hash or quadtree for collision detection to achieve O(n log n) or better
2. **Dirty Rectangle**: Only redraw changed portions of the screen
3. **Double Buffering**: Maintain an off-screen buffer to reduce flicker
4. **SIMD Optimizations**: Use SIMD instructions for vector operations if available
