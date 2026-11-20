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
    <div className={className}>
      <nav role="tablist" aria-label="Status filter tabs" className="flex flex-wrap gap-2">
        {tabs.map((tab) => {
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              role="tab"
              aria-selected={isActive}
              type="button"
              onClick={() => onChange(tab.id)}
              className="tab"
            >
              <span>{tab.label}</span>
              {typeof tab.count === "number" && (
                <span className="opacity-80">{tab.count.toLocaleString("en-US")}</span>
              )}
            </button>
          );
        })}
      </nav>
    </div>
  );
}
