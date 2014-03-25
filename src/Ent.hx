import Common;
import hxd.Key in K;
import hxd.Math;

class Ent extends h2d.Sprite
{
	static var UID = 0;
	
	public var width:Float;
	public var height:Float;
	public var ray:Float;
	
	public var id:Int;
	public var vx:Float;
	public var vy:Float;
	var vz:Float;
	var z:Float;
	var frict:Float;

	public var pv:Float;
	public var dead:Bool;	
	var death:Int;
	public var active:Bool;	
	public var anim:h2d.Anim;
	public var mc:h2d.Graphics;

	var game:Game;
	
	public var name:String;
	
	public var type:TypeEnt<Dynamic>;
	
	
	public function new (x, y, layer:Int = -1)
	{
		name = '';
		type = RIEN;
		active = true;
		
		id = UID++;
		
		if (layer == -1) layer = Const.L_UNIT;
		super();

		this.x = x;
		this.y = y;
		
		game = Game.inst;
		game.ents.push(this);
		game.board.add(this, layer);
		pv = 1;
		vx = 0;
		vy = 0;
		vz = 0;
		z = 0;
		frict = 1;
		dead = false;
		
		anim = new h2d.Anim(this);
		anim.loop = true;
		anim.speed = 15;
		anim.colorKey = 0xFFFFFFFF;
		addChild(anim);
		
		death = 0;		
	}
	
	public inline function toType<T:Ent>( t : TypeEnt<T> ) : T {
		return type == t ? cast this  : null;
	}
	
	public function update( dt : Float )
	{
		if (dead) {
			if (death == 1) {
				kill();
				return;
			}
			death--;
		}
		
		var tf = Math.pow(frict, dt);
		vx *= tf;
		x += vx * dt;
		vy *= tf;
		y += vy * dt;

	}
	
	public function onCollide(e:Ent) {}

	public function looseLife(nb:Float = 1) 
	{
		pv -= nb;
		if (pv <= 0)
			destroy();
	}
	
	function destroy()
	{
		dead = true;
		death = 1;
	}
	
	public function kill() 
	{
		dead = true;
		game.ents.remove(this);
		anim.remove();
		remove();
	}		
	
	public function toString() {
		return 'id ' + id + ' : ' + type + ', ' + x + ', ' + y + ', ' + width + ', ' + height;
	}
}