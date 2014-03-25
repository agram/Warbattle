import Common;

class Joueur
{
	var game:Game;
	
	public var troups: Array<Troup>;
	public var obstacle: Array<Int>;
	public var selectedTroup: Troup;
	public var selectedSkill: Skill;
	public var cooldownScan: Int;
	public var isPlayer:Bool;
	
	var livingTroups:Array<h2d.Anim>;	

	public var resurectHero: {
		cooldown: Int,
		x: Float,
		y: Float,
	};
		
	public function new(isPlayer:Bool) 
	{
		game = Game.inst;
		
		troups = [];
		obstacle = [];
		selectedSkill = null;
		selectedTroup = null;
		cooldownScan = 0;
		
		resurectHero = {
			cooldown: 0,
			x: 0,
			y: 0,
		};
		
		this.isPlayer = isPlayer;
		
		livingTroups = [];
	}

	public function initLivingTroups () {
		for (a in livingTroups.copy()) {
			game.boardUi.removeChild(a);
			livingTroups.remove(a);
			a.remove();
		}
		var nb = 0;
		for (t in troups) {
			if (t.dead) continue;
			var a = new h2d.Anim(
				if(isPlayer)
					switch(t.code) {
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
					}
				else	
					switch(t.code) {
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
					}
			);
			a.scale(0.5);
			if (isPlayer) a.x = 8 + 16 * nb;
			else a.x = 690 + 16 * nb;
			a.y = 410;
			a.colorKey = 0xFFFFFFFF;
			livingTroups.push(a);
			nb++;
			game.boardUi.addChild(a);
		}
	}
	
	public function update() {
		updateResurectHero();
		updateScan();
	}
	
	static public function startScan(troup:Troup) {
		new TimerEffect(SCAN, troup);
		var g = troup.ally();
		var h = troup.ennemy();
		g.cooldownScan = Skill.getExecutingTime(SCAN);
		for (t in Game.inst.traps) if (t.player != troup.isPlayer()) t.visible = true;
	}
	
	public function updateScan() {
		if (cooldownScan > 0) cooldownScan--;
	}
	
	public function scan() {
		return cooldownScan > 0;
	}
	
	public function updateResurectHero () {
		if (resurectHero.cooldown > 0) resurectHero.cooldown--;
		if (resurectHero.cooldown == 1) {
			var h = new Troup(resurectHero.x, resurectHero.y, HERO, ( (isPlayer) ? 1 : 2 ) );
			h.initSkills();
			troups.push(h);

			initLivingTroups();
		}
	}
}