import { describe, expect, it } from "vitest";
import { routeForActivityType } from "@/lib/routes";

describe("routeForActivityType", () => {
  it("maps supported activity types to the expected route segments", () => {
    expect(routeForActivityType("passive")).toBe("passive");
    expect(routeForActivityType("twoway")).toBe("chat");
    expect(routeForActivityType("media")).toBe("media");
  });
});
