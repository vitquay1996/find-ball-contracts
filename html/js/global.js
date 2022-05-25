(function($)
{
	// DOM elems
	var $game;
	var $cups;
	var $ball;
	var $gameResult;
	var $playBtn;

	function initGame()
	{
		// Config vars
		var animSpeed = 100;
		var intervalSpeed = animSpeed + 100;
		var nbMaxSwaps = 15;
		
		// Game vars
		var posBall;
		var animsInterval;
		var cupsWidth = $cups.outerWidth(true);
		var nbCups = $cups.length;
		var nbSwaps = 0;

		// Animation
		function move($elemToMove, dir, depth, nbMoves)
		{
			var distanceAnim = cupsWidth * nbMoves / 2;
			var zindex = 'auto';
			var scale;

			if(depth > 0)
			{
				zindex = 5;
				scale = 1.25;
			}else
			{
				scale = 0.75;
				zindex = -5;
			}

			if(dir === 'left')
			{
				dir = '-';
			}else
			{
				dir = '+';
			}
      
      		$elemToMove
        		.css('z-index', zindex)
				.transition
				(
					{
						x: dir + '=' + distanceAnim,
						scale: scale
					},
					{
						duration: animSpeed / 2,
						easing: 'linear'
					}
				)
				.transition
				(
					{
						x: dir + '=' + distanceAnim,
						scale: 1
          			},
          			{
						duration: animSpeed / 2,
						easing: 'linear',
						complete: function()
						{
							$elemToMove.css('z-index', 'auto');
               
							nbSwaps += 0.5;
               				
							if(nbSwaps >= nbMaxSwaps)
							{
								clearInterval(animsInterval);
								end();
							}
						}
					}
				);
		}

		function moveToLeft($elemToMove, depth, nbMoves)
		{
			move($elemToMove, 'left', depth, nbMoves);
		}

		function moveToRight($elemToMove, depth, nbMoves)
		{
			move($elemToMove, 'right', depth, nbMoves);
		}

		// Swaps cups position
		function swapElems($firstCup, $secondCup)
		{
			var posFirstCup = $firstCup.data('posCurrent');
			var posSecondCup = $secondCup.data('posCurrent');
			var nbMoves = Math.abs(posFirstCup - posSecondCup);

			if(posFirstCup > posSecondCup)
			{
				moveToLeft($firstCup, 1, nbMoves);
				moveToRight($secondCup, 0, nbMoves);
			}else
			{
				moveToRight($firstCup, 0, nbMoves);
				moveToLeft($secondCup, 1, nbMoves);
			}

			$firstCup.data('posCurrent', posSecondCup);
			$secondCup.data('posCurrent', posFirstCup);
		}

		function animateCups()
		{
			var posCups = [];
			var indexFirstCup = Math.floor(Math.random() * nbCups);
			var indexSecondCup;
			var $firstCup;
			var $secondCup;

			for(var i = 0; i < nbCups; i++)
			{
				posCups[i] = i;
			}

			posCups.splice(indexFirstCup, 1);

			indexSecondCup = posCups[Math.floor(Math.random() * (nbCups - 1))];

			$firstCup = $cups.eq(indexFirstCup);
			$secondCup = $cups.eq(indexSecondCup);

			swapElems($firstCup, $secondCup);
		}
    

		// Starts a game
		function start()
		{
			nbSwaps = 0;
			posBall = Math.floor(Math.random() * nbCups);
      
			$playBtn.off('click');
			$game.off('click');
			
			// Update of cups position
			$cups.each(function()
			{
				var posEnd = $(this).data('posCurrent');
				$(this).data('posStart', posEnd);
			});

			// Shows the ball
			$ball
				.css('left', posBall * cupsWidth)
				.fadeIn()
				.delay(600)
				.fadeOut(function()
        		{
					// Cups swaping
          			animsInterval = setInterval(animateCups, intervalSpeed);
        		});
		}

		// End of game
		function end()
		{	
			$playBtn.on('click', start);
      
			$game.on('click', '.cup', function()
			{
				var posStart = $(this).data('posStart');
				var posEnd = $(this).data('posCurrent');

				// If the ball is found
				if(posBall === posStart)
				{
					$game.off('click', '.cup');
					
					// Shows the ball
					$ball
						.css('left', posEnd * cupsWidth)
						.stop(true, false)
						.fadeIn()
						.delay(600)
						.fadeOut();
          
					$gameResult.text('Ball found !');
				}
				else
				{
					$gameResult.text('Try again !');
				}
        
				$gameResult
					.stop(true, false)
					.fadeIn()
					.delay(600)
					.fadeOut();
			});
		}

		function init()
		{
			// Init positions
			$cups.each(function(i)
			{
				$(this).data({ posStart: i, posCurrent: i });
			});

			$playBtn.on('click', start);
		}

		// Game init
		init();
	};

	$(document).ready(function()
	{
		$game = $('#game');
		$cups = $game.find('.cup');
		$ball = $game.find('.ball');
		$gameResult = $game.find('#game-result');
    	$playBtn = $('#btn-play');

		initGame();
	});

})(jQuery);