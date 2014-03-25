import Common;

class IconeTroup extends Ent {
		
	public var troup:Troup;
	public static var ALPHA = 0.65;
	public var toolTip:Tips;
	public var stats:Message.StatsTroup;
	public var lifeBarTotal:h2d.Graphics;
	public var lifeBar:h2d.Graphics;
	public var skillBarTotalFirst:h2d.Graphics;
	public var skillBarFirst:h2d.Graphics;
	public var skillBarTotalSecond:h2d.Graphics;
	public var skillBarSecond:h2d.Graphics;
	
	public var animLooseLife:Int;

	public function new (troup:Troup) {
		
		super(troup.x, troup.y);
		type = TROUP;
		this.troup = troup;
		
		ray = troup.ray;
		width = troup.ray * 2;
		height = troup.ray * 2;

		setAnim();
		
		anim.x = -16;
		anim.y = -16;
		
		addChild(anim);
		
		troup.selected = false;
		
		initBars();
		
		animLooseLife = 0;
		
		//visible = troup.isPlayer();
	}
	
	override function update(dt:Float) {
		if (toolTip != null) if(toolTip.update(dt, x, y)) killToolTip(); // renvoie true pour mourir et false pour rester en vie
		
		if (troup.goal != null || troup.charging != null) {
			var d:Float;
			if (troup.charging != null)
				d = Tools.distanceSquare(troup.x, troup.charging.x, troup.y, troup.charging.y);
			else
				// Pour un mouvement diesel, démarrage lent, acceleration mais freinage
				d = Tools.distanceSquare(troup.x, troup.goal.x, troup.y, troup.goal.y);

			frict = (d < 25 || troup.isFighting()) ? 0.93 : 0.97;
			
			vx += (troup.x - x) / 500;
			vy += (troup.y - y) / 500;
		}
		if (troup.pv < troup.caracs.life) lifeBarTotal.visible = true;
		
		lifeBar.scaleX = troup.pv / troup.caracs.life;
		
		if (troup.isPlayer()) {

			if (skillBarTotalFirst != null) {
				var s = troup.getSkill(troup.caracs.skills.first);
				skillBarFirst.scaleY = 1 - s.cooldown / s.cooldownMax;
			}
			if (skillBarTotalSecond != null) {
				var s = troup.getSkill(troup.caracs.skills.second);
				skillBarSecond.scaleY = 1 - s.cooldown / s.cooldownMax;
			}
			
		}

		if (animLooseLife > 0) animLooseLife--;
			
		scaleX = (100 - animLooseLife) / 100;
		scaleY = (100 - animLooseLife) / 100;
		
		super.update(dt);
		
	}

	public function setAnim() {
		
		if(!troup.selected) {
			if(troup.isPlayer())
				anim.play( switch(troup.code) {
					case CHASSEUR: game.gfx.personnages.gentilNormal.chasseur;
					case ARCHER: game.gfx.personnages.gentilNormal.archer;
					case TANK: game.gfx.personnages.gentilNormal.tank;
					case SOLDAT: game.gfx.personnages.gentilNormal.soldat;
					case TROLL: game.gfx.personnages.gentilNormal.troll;
					case MAGICIEN: game.gfx.personnages.gentilNormal.magicien;
					case NECROMANCIEN: game.gfx.personnages.gentilNormal.necromancien;
					case ASSASSIN: game.gfx.personnages.gentilNormal.assassin;
					case ORACLE: game.gfx.personnages.gentilNormal.oracle;
					case HERO: game.gfx.personnages.gentilNormal.hero;
				});
			else	
				anim.play( switch(troup.code) {
					case CHASSEUR: game.gfx.personnages.mechant.chasseur;
					case ARCHER: game.gfx.personnages.mechant.archer;
					case TANK: game.gfx.personnages.mechant.tank;
					case SOLDAT: game.gfx.personnages.mechant.soldat;
					case TROLL: game.gfx.personnages.mechant.troll;
					case MAGICIEN: game.gfx.personnages.mechant.magicien;
					case NECROMANCIEN: game.gfx.personnages.mechant.necromancien;
					case ASSASSIN: game.gfx.personnages.mechant.assassin;
					case ORACLE: game.gfx.personnages.mechant.oracle;
					case HERO: game.gfx.personnages.mechant.hero;
				});
		}
		else {
			anim.play( switch(troup.code) {
				case CHASSEUR: game.gfx.personnages.gentilSelected.chasseur;
				case ARCHER: game.gfx.personnages.gentilSelected.archer;
				case TANK: game.gfx.personnages.gentilSelected.tank;
				case SOLDAT: game.gfx.personnages.gentilSelected.soldat;
				case TROLL: game.gfx.personnages.gentilSelected.troll;
				case MAGICIEN: game.gfx.personnages.gentilSelected.magicien;
				case NECROMANCIEN: game.gfx.personnages.gentilSelected.necromancien;
				case ASSASSIN: game.gfx.personnages.gentilSelected.assassin;
				case ORACLE: game.gfx.personnages.gentilSelected.oracle;
				case HERO: game.gfx.personnages.gentilSelected.hero;
			});			
		}
			
		
	}
	
	function initBars () {
		lifeBarTotal = new h2d.Graphics(this);
		lifeBarTotal.beginFill(0xFF0000);
		lifeBarTotal.drawRect(0, 0, ray, 2);
		lifeBarTotal.endFill();
		
		lifeBar = new h2d.Graphics(lifeBarTotal);
		lifeBar.beginFill(0x00FF00);
		lifeBar.drawRect(0, 0, ray, 2);
		lifeBar.endFill();
		
		lifeBarTotal.x = -ray / 2;
		lifeBarTotal.y = -ray;
		
		lifeBarTotal.visible = false;
		
		if (!troup.isPlayer()) return;
		
		switch(troup.caracs.skills.first) {
			case POISON, CHARGE_FRENETIC, TELEPORTATION, CURSE, CLOACK, DODO:
		
				skillBarTotalFirst = new h2d.Graphics(this);
				skillBarTotalFirst.beginFill(0xFF0000);
				skillBarTotalFirst.drawRect(0, 0, 2, ray / 2);
				skillBarTotalFirst.endFill();
				
				skillBarFirst = new h2d.Graphics(skillBarTotalFirst);
				skillBarFirst.beginFill(0x00FF00);
				skillBarFirst.drawRect(0, 0, 2, ray / 2);
				skillBarFirst.endFill();
				
				skillBarTotalFirst.x = -ray + 3;
				skillBarTotalFirst.y = ray / 2;
				
				skillBarTotalFirst.visible = true;
				
			default:
				skillBarTotalFirst = null;
		}
		
		switch(troup.caracs.skills.second) {
		
			case PIEGE, SPRINT, COUP_BOUCLIER, ATTAQUE_TOURNOYANTE, BERSERK, FIREBALL, METAMORPHOSE, ASSASSINAT, SCAN, RESURECT :
				
				skillBarTotalSecond = new h2d.Graphics(this);
				skillBarTotalSecond.beginFill(0xFF0000);
				skillBarTotalSecond.drawRect(0, 0, 2, ray / 2);
				skillBarTotalSecond.endFill();
				
				skillBarSecond = new h2d.Graphics(skillBarTotalSecond);
				skillBarSecond.beginFill(0x00FF00);
				skillBarSecond.drawRect(0, 0, 2, ray / 2);
				skillBarSecond.endFill();
				
				skillBarTotalSecond.x = -ray + 6;
				skillBarTotalSecond.y = ray / 2;
				
				skillBarTotalSecond.visible = true;
				
			default :
				skillBarTotalSecond = null;
		}
		
	}
	
	override public function destroy() {
		super.destroy();
		kill();		
	}
	
	public function showStats() {
		var text = troup.code + ' ' + troup.numero;
		if (troup.selected) text += '\n\nSELECTED';	
		stats.texte.text = text;	
	}
	
	public function createToolTip() {
		toolTip = new Tips();
		toolTip.time = 50;
		toolTip.texte.text = troup.getDescription();
		game.board.add(toolTip, Const.L_UP);
	}
	
	public function killToolTip() {
		toolTip.remove();
		toolTip = null;
	}
}
