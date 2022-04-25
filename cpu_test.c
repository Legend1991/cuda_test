#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "acpc_server_code/game.h"

const uint32_t LENGTH = MAX_SUITS * MAX_RANKS;

typedef enum
{
  Win = 0,
  Lose,
  Tie
} Res;

typedef struct
{
  uint8_t boardCards[5];
  Res res;
} GameRes;

int main(void)
{
  // uint8_t p1[2] = {makeCard(12, 2), makeCard(11, 0)};
  uint8_t p2[2] = {makeCard(10, 1), makeCard(8, 1)};

  const uint16_t P1_HAND_SET_SIZE = 338; // 169 * 2 (two cards per hand)
  uint8_t p1HandSet[P1_HAND_SET_SIZE] = {
      0, 4, 0, 8, 0, 12, 0, 16, 0, 20, 0, 24, 0, 28, 0, 32, 0, 36, 0, 40, 0, 44, 0, 48, 4, 8, 4, 12, 4, 16, 4, 20, 4, 24, 4, 28, 4, 32, 4, 36, 4, 40, 4, 44, 4, 48, 8, 12, 8, 16, 8, 20, 8, 24, 8, 28, 8, 32, 8, 36, 8, 40, 8, 44, 8, 48, 12, 16, 12, 20, 12, 24, 12, 28, 12, 32, 12, 36, 12, 40, 12, 44, 12, 48, 16, 20, 16, 24, 16, 28, 16, 32, 16, 36, 16, 40, 16, 44, 16, 48, 20, 24, 20, 28, 20, 32, 20, 36, 20, 40, 20, 44, 20, 48, 24, 28, 24, 32, 24, 36, 24, 40, 24, 44, 24, 48, 28, 32, 28, 36, 28, 40, 28, 44, 28, 48, 32, 36, 32, 40, 32, 44, 32, 48, 36, 40, 36, 44, 36, 48, 40, 44, 40, 48, 44, 48, // Suited
      0, 1, 4, 5, 8, 9, 12, 13, 16, 17, 20, 21, 24, 25, 28, 29, 32, 33, 36, 37, 40, 41, 44, 45, 48, 49,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           // Pairs
      0, 5, 0, 9, 0, 13, 0, 17, 0, 21, 0, 25, 0, 29, 0, 33, 0, 37, 0, 41, 0, 45, 0, 49, 4, 9, 4, 13, 4, 17, 4, 21, 4, 25, 4, 29, 4, 33, 4, 37, 4, 41, 4, 45, 4, 49, 8, 13, 8, 17, 8, 21, 8, 25, 8, 29, 8, 33, 8, 37, 8, 41, 8, 45, 8, 49, 12, 17, 12, 21, 12, 25, 12, 29, 12, 33, 12, 37, 12, 41, 12, 45, 12, 49, 16, 21, 16, 25, 16, 29, 16, 33, 16, 37, 16, 41, 16, 45, 16, 49, 20, 25, 20, 29, 20, 33, 20, 37, 20, 41, 20, 45, 20, 49, 24, 29, 24, 33, 24, 37, 24, 41, 24, 45, 24, 49, 28, 33, 28, 37, 28, 41, 28, 45, 28, 49, 32, 37, 32, 41, 32, 45, 32, 49, 36, 41, 36, 45, 36, 49, 40, 45, 40, 49, 44, 49  // Unsuited
  };

  Game *game;
  char game_file[] = "./games/holdem.nolimit.2p.reverse_blinds.game";
  FILE *file = fopen(game_file, "r");
  if (file == NULL)
  {
    fprintf(stderr, "failed to open game file [%s]\n", game_file);
    exit(-1);
  }
  game = readGame(file);
  if (game == NULL)
  {
    fprintf(stderr, "failed to read game file [%s]\n", game_file);
    exit(-1);
  }

  State state;
  state.round = game->numRounds - 1;
  // state.holeCards[0][0] = p1[0];
  // state.holeCards[0][1] = p1[1];
  state.holeCards[1][0] = p2[0];
  state.holeCards[1][1] = p2[1];

  uint32_t count = 0;
  uint64_t pWins = 0;
  uint64_t vWins = 0;
  uint64_t ties = 0;

  clock_t start = clock();

  GameRes *gameRes;
  gameRes = (GameRes *)malloc(sizeof(*gameRes) * 1712304);

  for (uint16_t p1Idx = 0; p1Idx < P1_HAND_SET_SIZE; p1Idx += 2)
  {
    uint8_t p1[2] = {p1HandSet[p1Idx], p1HandSet[p1Idx + 1]};

    state.holeCards[0][0] = p1[0];
    state.holeCards[0][1] = p1[1];

    const uint32_t DECK_SIZE = 48;
    uint8_t deck[DECK_SIZE];

    for (uint8_t c = 0, i = 0; c < LENGTH; ++c)
    {
      if (c == p1[0] || c == p1[1] || c == p2[0] || c == p2[1])
        continue;

      deck[i] = c;
      ++i;
    }

    for (uint8_t f1Idx = 0; f1Idx < DECK_SIZE; ++f1Idx)
    {
      for (uint8_t f2Idx = f1Idx + 1; f2Idx < DECK_SIZE; ++f2Idx)
      {
        for (uint8_t f3Idx = f2Idx + 1; f3Idx < DECK_SIZE; ++f3Idx)
        {
          for (uint8_t tIdx = f3Idx + 1; tIdx < DECK_SIZE; ++tIdx)
          {
            for (uint8_t rIdx = tIdx + 1; rIdx < DECK_SIZE; ++rIdx)
            {
              state.boardCards[0] = deck[f1Idx];
              state.boardCards[1] = deck[f2Idx];
              state.boardCards[2] = deck[f3Idx];
              state.boardCards[3] = deck[tIdx];
              state.boardCards[4] = deck[rIdx];

              int pRank = rankHand(game, &state, 0);
              int vRank = rankHand(game, &state, 1);

              GameRes *g = &gameRes[count];

              g->boardCards[0] = deck[f1Idx];
              g->boardCards[1] = deck[f2Idx];
              g->boardCards[2] = deck[f3Idx];
              g->boardCards[3] = deck[tIdx];
              g->boardCards[4] = deck[rIdx];

              if (pRank == vRank)
              {
                ++ties;
                g->res = Tie;
              }
              else if (pRank > vRank)
              {
                ++pWins;
                g->res = Win;
              }
              else
              {
                ++vWins;
                g->res = Lose;
              }

              ++count;
            }
          }
        }
      }
    }
  }

  clock_t end = clock();
  double diff = (double)(end - start) / (double)(CLOCKS_PER_SEC);

  printf("Calc took: %0.10f\n", diff);
  // printf("pWins: %d\n", pWins);
  // printf("vWins: %d\n", vWins);
  // printf("ties: %d\n", ties);
  // printf("count: %d\n", count);

  return 0;
}