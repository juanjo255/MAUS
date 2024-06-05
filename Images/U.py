# %%
import plotly.graph_objects as go
import numpy as np

# Seed for reproducibility
np.random.seed(42)

# Generate x values for each cluster
x1 = np.random.uniform(-10, -5, 500)
x2 = np.random.uniform(-5, 5, 500)
x3 = np.random.uniform(5, 10, 500)

# Define the quadratic function for the U shape
a, b, c = 1, 0, 0  # Coefficients for the quadratic equation

# Calculate y values and add some noise for each cluster
y1 = a * x1**2 + b * x1 + c + np.random.normal(0, 5, x1.shape)
y2 = a * x2**2 + b * x2 + c + np.random.normal(0, 5, x2.shape)
y3 = a * x3**2 + b * x3 + c + np.random.normal(0, 5, x3.shape)

for k,v in enumerate(x1):
    if v < -5:
        x1[k] = np.random.uniform(-8, -4)
        y1[k] = np.random.uniform(30, 100)
for k,v in enumerate(x3):
    if v > 7.5:
        x3[k] = np.random.uniform(6, 8)
        y3[k] = np.random.uniform(60, 100)

# Create scatter plot
fig = go.Figure()

fig.add_trace(go.Scatter(x=x1, y=y1, mode='markers', marker=dict(color='#FF6347', size=10), name='Cluster 1'))
fig.add_trace(go.Scatter(x=x2, y=y2, mode='markers', marker=dict(color='#3CB371', size=10), name='Cluster 2'))
fig.add_trace(go.Scatter(x=x3, y=y3, mode='markers', marker=dict(color='#1E90FF', size=10), name='Cluster 3'))

# Update layout for a clean look
#fig.update_layout(showlegend=False, plot_bgcolor='white', xaxis=dict(visible=False), yaxis=dict(visible=False), width=800, height=800)

fig.write_image("U.jpeg")
# Show the plot
fig.show()


