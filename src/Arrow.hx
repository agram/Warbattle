import Common;

class Arrow extends Ent
{
	var goalX:Float;
	var goalY:Float;
	var from:Troup;
	var target:Troup;
	var ds:Float;
	var typeArrow:TypeArrow;
	
	public function new(x:Float, y:Float, from:Troup, target:Troup, typeArrow:TypeArrow) 
	{
		super(x, y);
		this.from = from;
		this.target = target;
		if (typeArrow == NORMAL) {
			switch(from.code) {
				case MAGICIEN, NECROMANCIEN, ORACLE: typeArrow = MAGIC;
				default: NORMAL;
			}
		}
		else this.typeArrow = typeArrow;
		from.poison = false;
		
		frict = 0.97;
		
		switch (typeArrow) {
			case POISON :
				anim.play(game.gfx.particule.arrowPoison);
				scale(2);
			case NORMAL : anim.play(game.gfx.particule.arrow);
			case BARRAGE : anim.play(game.gfx.particule.arrow); anim.scale(4);
			case MAGIC : 
				anim.play(game.gfx.particule.arrowMagic);
				scale(2);
		}

		var teta = Math.atan2(target.y - y, target.x - x);
		rotate(teta);

		anim.scaleX = anim.scaleY = 0.5;
		anim.x = -4;
		anim.y = -4;
		
		ds = 0;
	}
	
	
	override public function update(dt:Float) {
		
		ds = Tools.distanceSquare(x, target.x, y, target.y);

		if (target.dead && ds < target.ray * target.ray) kill();
		
		vx += (target.x - x) / 500;
		vy += (target.y - y) / 500;
		
		super.update(dt);
		
	}
	
	override function onCollide (e:Ent) {
		
		var f = e.toType(TROUP);
		if (f == null) return;
		
		if (f.troup.numero != target.numero) return;

		if (ds > target.ray * target.ray + 25) return;
		
		var damage:Float = from.caracs.longDistance.damage;
		
		if (typeArrow == BARRAGE) damage *= 20;
		if (f.troup.code == TANK) damage = f.troup.leverBouclier(damage);
		if (typeArrow == POISON) new TimerEffect(POISON, target);
		
		if (from.getPoweraura()) damage *= 1.1;
		
		target.looseLife(Std.int(damage), TIR);
			
		kill();
	}
}