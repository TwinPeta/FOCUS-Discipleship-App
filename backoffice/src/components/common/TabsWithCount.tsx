/**
 * src/components/common/TabsWithCount.tsx
 *
 * WHAT: Accessible tabs with item counts and URL state sync support
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

export interface TabItem<T extends string = string> {
  id: T;
  label: string;
  count?: number;
}

interface TabsWithCountProps<T extends string = string> {
  tabs: TabItem<T>[];
  activeTab: T;
  onChange: (tabId: T) => void;
  className?: string;
}

export function TabsWithCount<T extends string = string>({
  tabs,
  activeTab,
  onChange,
  className = "",
}: TabsWithCountProps<T>) {
  return (
    <div className={`border-b border-border ${className}`}>
      <nav role="tablist" aria-label="Status filter tabs" className="flex space-x-6">
        {tabs.map((tab) => {
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              role="tab"
              aria-selected={isActive}
              type="button"
              onClick={() => onChange(tab.id)}
              className={`flex items-center gap-2 border-b-2 py-3 text-sm font-semibold transition ${
                isActive
                  ? "border-primary text-foreground"
                  : "border-transparent text-muted hover:border-slate-300 hover:text-foreground"
              }`}
            >
              <span>{tab.label}</span>
              {typeof tab.count === "number" && (
                <span
                  className={`rounded-full px-2 py-0.5 text-[11px] font-bold ${
                    isActive
                      ? "bg-primary-soft text-foreground"
                      : "bg-slate-100 text-muted"
                  }`}
                >
                  {tab.count}
                </span>
              )}
            </button>
          );
        })}
      </nav>
    </div>
  );
}
