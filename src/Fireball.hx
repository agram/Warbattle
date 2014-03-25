import Common;

class Fireball extends Ent
{	
	var cooldown:Int;
	
	public function new(x, y) 
	{
		super(x, y, Const.L_UP);
		
		width = 32;
		height = 32;
		
		anim.play(game.gfx.particule.fireball);
		anim.rotate(Math.PI / 2);
		anim.x = 16;
		anim.y = -24;
		
		var fg = h2d.Tile.fromColor(0x80808080, 10, 10);
		var b = new h2d.Bitmap(fg, this);
		b.x = -5;
		b.y = -5;
		
		cooldown = Skill.getExecutingTime(FIREBALL);
	}
	
	override public function update(dt:Float) {
		cooldown--;
		if (cooldown <= 0) kill();
	}
	
	override public function onCollide(e:Ent) {
		var f = e.toType(TROUP);
		if (f == null) return;
		
		if (Math.abs(x - f.x) < width && Math.abs(y - f.y) < height)
			f.troup.looseLife(3, MAGIC);
	}
}