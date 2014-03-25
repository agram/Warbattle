import Common;

class Item {
	public var x:Int;
	public var y:Int;
	public var numero:Int;
	public var cout:Float;
	public var next : Item;
	
	public function new(x, y, numero = 0, cout:Float = 0) {
		this.x = x;
		this.y = y;
		this.numero = numero;
		this.cout = cout;
		this.next = null;
	}
	
	public function toString() {
		return 'x:' + x + ', y:' + y + ', n:' + numero + ', c:' + cout;
	}
	
	inline public function free() {
		next = Game.cacheItem;
		Game.cacheItem = this;
	}
	
	public function length() {
		if (this == null) return 0;
		var nb = 1;
		var p = this;
		while (p.next != null) {
			p = p.next;
			nb++;
		}
		return nb;
	}
	
}

class Path
{
	var game:Game;
	var matrix:Array<Int>;
	public var firstItem:Item;
	var x:Int;
	var y:Int;
	var goalX:Int;
	var goalY:Int;
	
	var troup:Troup;
	
	public var point:{x:Int, y:Int};
	
	public function new(startX, startY, goalX, goalY, troup:Troup) {
		
		this.goalX = goalX;
		this.goalY = goalY;
		
		game = Game.inst;
		this.troup = troup;
		
		//trace("START");
		//var t0 = haxe.Timer.stamp();
		
		// J'initialise la matrice qui va enregistrer tous les déplacements possibles.
		matrix = [];
		
		//trace(haxe.Timer.stamp() - t0);
		//var t0 = haxe.Timer.stamp();
		
		// Je place le point de départ et je l'enregistre pour commencer le traitement
		matrix[startX + Const.MAP_WIDTH * startY] = 0;
		firstItem = getItem(startX, startY, 0, 0);

		var continu = true;
		
		// On tourne tant que l'on a encore des points à traiter
		// Si on trouve l'objectif, on vide le tableau et on stope
		while (continu && firstItem != null) {
			// Si il y a plusieurs points ayant le même poids, j'en prend un au hasard.
			var p = firstItem.next;
			var nb = 1;
			while (p != null && firstItem.cout == p.cout) {
				p = p.next;
				nb++;
			}
			var rand = Std.random(nb);
			var current:Item;
			var preview:Item;
			if (rand == 0) { 
				current = firstItem; 
				firstItem = firstItem.next;
			}
			else { 
				current = firstItem.next; 
				preview = firstItem;
				for (i in 1...nb) {
					if (i == rand) { preview.next = current.next; break; }
					else { preview = preview.next; current = current.next; }
				}
			}
			
			
			// Le traitement met à jour le listPoint et renvoie true s'il faut continuer
			continu = searchNeighbors(current);
			// a ce niveau, le current ne sert plus à rien.
			current.free();
		}

		// Maintenant que l'on a trouvé notre chemin, on n'a plus besoin de la chaine.
		// On demenage donc tout dans le cache
		firstItem = freeAll(firstItem);
		
		//trace(haxe.Timer.stamp() - t0);
		//var t0 = haxe.Timer.stamp();
		
		// A ce niveau, normalement, on sait qu'il existe un chemin à suivre pour atteindre l'obectif.
		// Il suffit de remonter la piste
		// Je ne gere pas un point inatteignable pour l'instant donc le goal doit être testé avant.
		// i possede comme valeur le nombre de pas nécessaire pour atteindre l'objectif
		var nbMax = matrix[goalX + Const.MAP_WIDTH * goalY];
		var nb = 0;
		point = getItem( goalX, goalY );

		/*------------------------------------*/
		var liste = [];
		
		inline function testPoint(x, y) {
			if (matrix[x + Const.MAP_WIDTH * y] == nbMax - nb) {
				var a = getItem( x, y );
				liste.push(a);
				return 1;
			}
			return 0;
		}
		
		//On s'arrete quand on est revenu au départ ou quand on a avancé de 2 pixels
		while (nb < nbMax && nb < 2)  {
			nb++;			
			//on regarde chaque voisin pour en trouver 1 qui possede une valeur supérieur de 1 à la case précédente.
			var count = 0;
			if (point.x > 0)
				count += testPoint(point.x - 1, point.y);
			if (point.x < Const.MAP_WIDTH) 
				count += testPoint(point.x + 1, point.y);
			if (point.y > 0) 
				count += testPoint(point.x, point.y - 1);
			if (point.y < Const.MAP_HEIGHT) 
				count += testPoint(point.x, point.y + 1);

			if (count == 0) {
				point.x = goalX;
				point.y = goalY;
			}
			else {
				var rand = Std.random(count);

				point.x = liste[rand].x;
				point.y = liste[rand].y;

				for (l in liste) l.free();
				liste = [];
			}
		}

		for (l in liste) l.free();
		liste = [];

		return;
		// Maintenant point contient l'endroit précis sur lequel on veut poser la troupe pour ce tour dans la direction de la cible.

		//trace(haxe.Timer.stamp() - t0);
	}	
	
	function testNeighbor(x, y, numero) {
		var z = x + Const.MAP_WIDTH * y;
		var c = costAccess(z); // -1 ou -2 ou -3 signifie ne peut pas etre franchit !
		var a = matrix[z];

		if ( c > -1 && (a == 0 || a > numero) ) {

			matrix[z] = numero;
			// Si on est arrivé, on s'en va.
			if (x == goalX && y == goalY) return false;

			// sinon, on enregistre la case comme étant à traiter
			// On la place où il faut dans le tableau, du moins couteux (distance + nbStep) au plus couteux
			var cout = Tools.distanceSquare(x, goalX, y, goalY) +  numero + 2 * c ;
			var item = getItem( x, y, numero, cout );

			// dans le cas où l'on veut mettre item en premier
			if (firstItem == null || firstItem.cout > cout) {
				item.next = firstItem;
				firstItem = item;
			}
			else {
				var current = firstItem;
				while (true) {
					if (current.next == null) {
						current.next = item;
						break;
					}
					if (cout < current.next.cout ) {
						item.next = current.next;
						current.next = item; 
						break;
					}
					current = current.next;
				}
			}
		}
		return true;
	}
		
	// Cette fonction renvoie true s'il faut continuer et false s'il faut s'arréter
	function searchNeighbors(t:Item) {
		var n = t.numero + 1;
		var x = t.x;
		var y = t.y;
		
		// On teste les cases à gauche, droite, haut, bas
		if (x > 0) 
			if (!testNeighbor(x - 1, y, n)) return false;
		if (x < Const.MAP_WIDTH - 1 ) 
			if (!testNeighbor(x + 1, y, n)) return false;
		if (y > 0) 
			if (!testNeighbor(x, y - 1, n)) return false;
		if (y < Const.MAP_HEIGHT - 1 ) 
			if (!testNeighbor(x, y + 1, n)) return false;
			
		return true;
	}
	
	inline public function costAccess(z) { 
		if (troup.isPlayer()) 
			return game.player.obstacle[z];
		else 
			return game.opponent.obstacle[z];
	}	
	
	// --- pour le cache
	
	public inline function getItem(x, y, numero = 0, cout:Float = 0) 
	{
		if (Game.cacheItem == null) {
			return new Item (x, y, numero, cout); 
		}
		else {
			var a = Game.cacheItem;
			Game.cacheItem = Game.cacheItem.next;
			a.x = x;
			a.y = y;
			a.numero = numero;
			a.cout = cout;
			a.next = null;
			return a;
		}
	}

	inline public function freeAll(l:Item) {
		if (l == null) return null;
		var p = l;
		var i = 1;
		while (p.next != null) {
			i++;
			p = p.next;
		}
		p.next = Game.cacheItem;
		Game.cacheItem = l;
		return null;
	}
	
}