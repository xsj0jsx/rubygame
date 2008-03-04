#!/usr/bin/env ruby

# This program is released to the PUBLIC DOMAIN.
# It is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# This script is messy, but it demonstrates almost all of
# Rubygame's features, so it acts as a test program to see
# whether your installation of Rubygame is working.

require "rubygame"
require "rubygame/mediabag"
include Rubygame

$stdout.sync = true


Rubygame.init()


unless ($gfx_ok = (VERSIONS[:sdl_gfx] != nil))
  raise "SDL_gfx is not available. Bailing out." 
end



$media = MediaBag.new()

panda_pic = Surface.load_image("panda.png")
panda_pic.set_colorkey(panda_pic.get_at(0,0))
$media.store("panda.png", panda_pic)

class PandaBall < Sprite
	@@colors = [:red, :yellow, :blue,
	            :green, :orange, :purple,
	            :pink, :sky_blue]
	
	attr_accessor :vx, :vy, :speed
	def initialize(scene,pos)
		super(scene)
		@image = $media["panda.png"]
		@body.p = pos
		@size = 0.5 + rand() * 0.8
		@color = @@colors[ rand(@@colors.length) ]
		
		shape = CP::Shape::Circle.new( @body, 22 * @size, vect(0,0) )
		shape.e = 0.0
		shape.u = 0.5
		shape.mass = 10.0
		shape.offset = vect(0,0)
		add_shape( shape )
		recalc_mi()
		
		self.static = false
	end
	
	def _draw_sdl( camera )
		trans = camera.world_to_screen(:pos => @body.p, :size => @size)
		trans[:size] *= 23.0

		camera.mode.surface.draw_circle_s( trans[:pos].to_ary, trans[:size], @color )
		
		rect = Rect.new(0,0,trans[:size]*2,trans[:size]*2)
		rect.center = trans[:pos].to_ary
		
		camera.mode.dirty_rects << rect
		
		super
	end
	
	def _undraw_sdl( camera )
		trans = camera.world_to_screen(:pos => @body.p, :size => @size)
		trans[:size] *= 23.0
		
		rect = Rect.new(0,0,trans[:size]*2+2,trans[:size]*2+2)
		rect.center = trans[:pos].to_ary
		
		bg = camera.mode.background
		bg.blit( camera.mode.surface, rect, rect )
		
		camera.mode.dirty_rects << rect
		
		super
	end
	
	def update( event )
		# Kill it if it goes too far down, way off the screen
		mark_dead() if @body.p.y > 1000
	end
end

# Create the SDL window
screen = Screen.set_mode([320,240])

# Make the background surface
background = Surface.new(screen.size)

camera_mode = Camera::RenderModeSDL.new(screen, background, screen.make_rect, 1.0)
scene = Scene.new( camera_mode )
#scene.camera.position = vect(160,120)

scene.event_queue.ignore = [MouseMotionEvent]

scene.space.gravity = vect(0,100)

scene.clock.target_framerate = 100

class << scene
	def take_screenshot
		@camera.mode.surface.savebmp("rubygame3-sprite-test.bmp")
	end
	
	def toggle_smooth
		@smooth = true unless defined? @smooth # enabled by default
		@smooth = @smooth ? false : true
		@camera.mode.quality = @smooth ? 1.0 : 0.0
	end

	# 
	# MAKE ME SOME PANDAAAAAAAAAAS!!
	# 
	def add_panda( event )
		PandaBall.new( self, vect(*event.world_pos) )
	end
	
	def refresh
		@camera.mode.surface.update
	end
	
end

PandaBall.new( scene, vect(100,50) )

# When the event on the left happens, call the method on the right.
# It's so easy, it's magic!
scene.magic_hooks(:mouse_right  =>  :add_panda,
                  :print_screen =>  :take_screenshot,
                  :r            =>  :refresh,
                  :s            =>  :toggle_smooth,
                  :q            =>  Proc.new{ throw :quit },
                  :escape       =>  Proc.new{ throw :quit },
                  QuitEvent     =>  Proc.new{ throw :quit })

puts "Right click to make a Panda Ball!"

INFINITY = 15**100

floor = Sprite.new( scene ) {
	@body.m, @body.i = INFINITY, INFINITY
	
	shape = CP::Shape::Segment.new(@body, vect(0,120), vect(260,220), 1.0)
	shape.e = 0.2
	shape.u = 0.4
	shape.mass = INFINITY
	add_shape( shape )
	
	shape = CP::Shape::Segment.new(@body, vect(260,220), vect(320,120), 1.0)
	shape.e = 0.2
	shape.u = 0.4
	shape.mass = INFINITY
	add_shape( shape )
}


# Filling with colors in a variety of ways
background.fill( Color::ColorRGB.new([0.1, 0.2, 0.35]) )
background.fill( :black, [70,120,80,80] )
background.fill( "dark red", [80,110,80,80] )


floor.shapes.each { |s|
	background.draw_line_a( scene.camera.world_to_screen(:pos => s.ta)[:pos],
													scene.camera.world_to_screen(:pos => s.tb)[:pos], :black )
}

# Refresh the screen once. During the loop, we'll use 'dirty rect' updating
# to refresh only the parts of the screen that have changed.
background.blit(screen,[0,0])
screen.update()



update_time = 0
framerate = 0

catch(:quit) do
	loop do
		scene.step
		scene.camera.refresh()
		screen.title = "Rubygame3  [%d sprites] [%.1f fps]"%[scene.sprites.length, scene.clock.framerate]
	end
end

puts "Quitting!"
Rubygame.quit()