import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create new quest",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("quest-hive", "create-quest",
        [types.ascii("Exercise"),
         types.ascii("Do 30 minutes of exercise"),
         types.uint(100)],
        wallet_1.address)
    ]);
    
    assertEquals(block.receipts[0].result.expectOk(), "u1");
  },
});

Clarinet.test({
  name: "Can complete quest and gain XP",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("quest-hive", "create-quest",
        [types.ascii("Exercise"),
         types.ascii("Do 30 minutes of exercise"), 
         types.uint(100)],
        wallet_1.address),
      Tx.contractCall("quest-hive", "complete-quest",
        [types.uint(1)],
        wallet_1.address)
    ]);
    
    assertEquals(block.receipts[1].result.expectOk(), true);
    
    let stats = chain.callReadOnlyFn(
      "quest-hive",
      "get-user-level",
      [types.principal(wallet_1.address)],
      wallet_1.address
    );
    
    assertEquals(
      stats.result.expectSome(),
      `{experience: u100, level: u1}`
    );
  },
});
