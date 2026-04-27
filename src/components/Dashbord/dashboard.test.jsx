import React from "react";
import { render, screen, waitFor } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Dashboard from "./dashboard";

const mockUseAuth = vi.fn();
const mockGetDashboardStats = vi.fn();

vi.mock("../../contexts/useAuth", () => ({
  useAuth: () => mockUseAuth(),
}));

vi.mock("../../lib/adminApi", () => ({
  getDashboardStats: (...args) => mockGetDashboardStats(...args),
}));

vi.mock("./ChartSection", () => ({
  default: () => <div>Chart Section</div>,
}));

vi.mock("./statusGrid", () => ({
  default: ({ stats }) => <div data-testid="status-grid">{JSON.stringify(stats)}</div>,
}));

describe("Dashboard", () => {
  beforeEach(() => {
    mockUseAuth.mockReturnValue({ accessToken: "admin-token" });
    mockGetDashboardStats.mockReset();
  });

  it("loads and renders dashboard stats", async () => {
    mockGetDashboardStats.mockResolvedValue({ totalUsers: 42, reports: 3 });

    render(<Dashboard />);

    expect(screen.getByText("Loading dashboard metrics...")).toBeInTheDocument();

    await waitFor(() => {
      expect(mockGetDashboardStats).toHaveBeenCalledWith("admin-token");
    });

    expect(screen.getByTestId("status-grid")).toHaveTextContent("totalUsers");
    expect(screen.getByTestId("status-grid")).toHaveTextContent("42");
  });

  it("shows an error message when stats loading fails", async () => {
    mockGetDashboardStats.mockRejectedValue(new Error("Stats failed"));

    render(<Dashboard />);

    expect(await screen.findByText("Stats failed")).toBeInTheDocument();
  });
});
