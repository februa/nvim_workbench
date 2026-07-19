import type { Denops } from "jsr:@denops/std@7";
import type { ContextBuilder, Dpp, Plugin } from "jsr:@shougo/dpp-vim@3.0.0/types";
import { BaseConfig } from "jsr:@shougo/dpp-vim@3.0.0/config";

export class Config extends BaseConfig {
  override async config(args: {
    denops: Denops;
    contextBuilder: ContextBuilder;
    basePath: string;
    dpp: Dpp;
  }): Promise<{ plugins: Plugin[]; stateLines: string[] }> {
    args.contextBuilder.setGlobal({ protocols: ["git"] });
    const [context, options] = await args.contextBuilder.get(args.denops);
    const configDir = await args.denops.call("stdpath", "config") as string;
    const result = await args.dpp.extAction(
      args.denops,
      context,
      options,
      "toml",
      "load",
      { path: `${configDir}/dpp/plugins.toml`, options: { lazy: false } },
    ) as { plugins?: Plugin[]; stateLines?: string[] };

    return {
      plugins: result.plugins ?? [],
      stateLines: result.stateLines ?? [],
    };
  }
}
