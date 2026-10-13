/// Grid columns for the *content* width (sidebar already excluded).
int gridColumns(double width) =>
    width < 620 ? 1 : width < 1000 ? 2 : width < 1380 ? 3 : 4;

double pagePadding(double width) => width < 620 ? 16 : 28;
