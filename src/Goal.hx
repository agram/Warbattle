import Common;

class Goal extends Ent {
	public var owner:Troup;
	public var isTroup:Bool;
	public var target:Troup;
	public var lastGoalX:Float;
	public var lastGoalY:Float;
	
	public static function setGoalTroup(target:Troup, owner:Troup) {
		if (target == null) return null;
		
		var t = new Goal(target.x, target.y, owner);
		t.isTroup = true;
		t.target = target;
		t.owner = owner;
		return t;
	}
	
	public function new (x, y, owner:Troup) {
		super(x, y, Const.L_UP);
		this.isTroup = false;
		this.target = null;
		this.owner = owner;
		this.lastGoalX = x;
		this.lastGoalY = y;
		
		anim.play(game.gfx.particule.goal);
		anim.visible = false;
		anim.speed = 5;
		anim.x -= Troup.RAY / 2;
		anim.y -= Troup.RAY;
	}
	
	override public function update (dt:Float) {
		if (isTroup) {
			x = target.icone.x;
			y = target.icone.y;			
		}
	}
	
	override public function toString() {
		return 'isTroup : '  + isTroup + ', x:' + x + ', y:' + y; 
	}
	
	override function kill() {
		if (owner != null && owner.goal != null) owner.goal = null;
		super.kill();
	}
}
